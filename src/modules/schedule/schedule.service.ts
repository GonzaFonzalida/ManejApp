const HOLD_MINUTES = 10;
const CANCEL_WINDOW_HOURS = 6;
const RESCHEDULE_WINDOW_HOURS = 12;

import { ScheduleSlotRepository } from "./repositories/ScheduleSlotRepository";
import InstructorService from "../instructors/instructor.services";
import { DrivingClassService } from "../drivingClass/services";
import PaymentService from "../payments/payment.services";
import { NotificationService } from "@notifications/service";
import CustomizedError from "@shared/classes/CustomizedError";
import { logger } from "@shared/logging/LoggerConfig";
import { prisma } from "@config/prismaClient";
import { SlotStatus, BookingStatus, Role } from "@prisma/client";
import {
  InstructorPayoutStatus,
  splitGrossByAppCommissionPercent,
} from "../payments/payment-commission.policy";

function formatClassWhen(d: Date): string {
  return d.toLocaleString("es-AR", {
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export class ScheduleService {
  constructor(
    private scheduleRepo: ScheduleSlotRepository,
    private instructorService: InstructorService,
    private drivingClassService: DrivingClassService,
    private paymentService: PaymentService,
    private notificationService: NotificationService
  ) { }

  /** Para createSlot: obtiene el instructor del usuario autenticado (solo rol INSTRUCTOR). */
  async getInstructorIdByUserId(userId: number): Promise<{ id: number } | null> {
    const instructor = await prisma.instructor.findUnique({
      where: { userId },
      select: { id: true },
    });
    return instructor;
  }

  /** Misma regla que listados premium: usuario STUDENT con fila Student ausente la obtiene vía upsert. */
  private async ensureStudentRow(userId: number): Promise<{ id: number }> {
    return prisma.student.upsert({
      where: { userId },
      create: { userId },
      update: {},
      select: { id: true },
    });
  }

  async createSlot(instructorId: number, startTime: Date, endTime: Date) {
    const instructor = await this.instructorService.getInstructorProfile(instructorId);
    if (!instructor) throw new CustomizedError("Instructor no encontrado", 404);

    if (startTime >= endTime) throw new CustomizedError("La hora de fin debe ser posterior a la de inicio", 400);

    const slot = await prisma.$transaction(async (tx) => {
      const overlap = await tx.scheduleSlot.findFirst({
        where: {
          instructorId,
          startTime: { lt: endTime },
          endTime: { gt: startTime },
        },
        select: { id: true },
      });
      if (overlap) throw new CustomizedError("El slot se superpone con uno existente", 409);

      return tx.scheduleSlot.create({
        data: {
          instructorId,
          startTime,
          endTime,
          status: SlotStatus.AVAILABLE,
          heldUntil: null,
          drivingClassId: null,
        },
      });
    });

    logger.info("Slot de horario creado", { slotId: slot.id, instructorId });
    return slot;
  }

  async getSlotById(id: string) {
    const slot = await this.scheduleRepo.findById(id);
    if (!slot) throw new CustomizedError("Slot no encontrado", 404);
    return slot;
  }

  async getAvailableSlots(instructorId: number, startDate?: Date, endDate?: Date) {
    return this.scheduleRepo.findAvailableByInstructor(instructorId, startDate, endDate);
  }

  async getReservationPreview(slotId: string, userId: number) {
    const slot = await prisma.scheduleSlot.findUnique({
      where: { id: slotId },
      include: {
        instructor: {
          include: {
            user: {
              select: {
                name: true,
                surname: true,
              },
            },
          },
        },
      },
    });
    if (!slot) throw new CustomizedError("Slot no encontrado", 404);

    const student = await this.ensureStudentRow(userId);

    const now = new Date();
    const canReserveNow =
      slot.status === SlotStatus.AVAILABLE ||
      (slot.status === SlotStatus.HELD && !!slot.heldUntil && slot.heldUntil < now);

    const durationMinutes = Math.floor((slot.endTime.getTime() - slot.startTime.getTime()) / (1000 * 60));
    const hourlyRate = slot.instructor.hourlyRate ?? 45000;
    const amount = Math.round((hourlyRate / 60) * durationMinutes);
    const cancelDeadline = new Date(slot.startTime.getTime() - CANCEL_WINDOW_HOURS * 60 * 60 * 1000);
    const rescheduleDeadline = new Date(slot.startTime.getTime() - RESCHEDULE_WINDOW_HOURS * 60 * 60 * 1000);

    return {
      slotId: slot.id,
      instructorId: slot.instructorId,
      canReserveNow,
      availabilityMessage: canReserveNow
        ? "Disponible para reservar"
        : "Este horario ya no está disponible",
      durationMinutes,
      startsAt: slot.startTime.toISOString(),
      endsAt: slot.endTime.toISOString(),
      cancelDeadline: cancelDeadline.toISOString(),
      rescheduleDeadline: rescheduleDeadline.toISOString(),
      policySummary: {
        cancelWindowHours: CANCEL_WINDOW_HOURS,
        rescheduleWindowHours: RESCHEDULE_WINDOW_HOURS,
        text: `Cancelación permitida hasta ${CANCEL_WINDOW_HOURS}h antes. Reprogramación hasta ${RESCHEDULE_WINDOW_HOURS}h antes (próximamente).`,
      },
      priceSummary: {
        amount,
        currency: "ARS",
        hourlyRate,
        estimatedTotalLabel: `ARS ${Math.round(amount).toLocaleString("es-AR")}`,
      },
      instructorSnapshot: {
        id: slot.instructor.id,
        name: slot.instructor.user.name,
        surname: slot.instructor.user.surname,
        hourlyRate: slot.instructor.hourlyRate,
        bio: slot.instructor.bio,
        addressText: slot.instructor.addressText,
      },
      location: {
        addressText: slot.instructor.addressText,
        lat: slot.instructor.lat,
        lng: slot.instructor.lng,
        zoneLabel: slot.instructor.addressText,
      },
    };
  }

  async reserveSlot(slotId: string, userId: number) {
    const slot = await this.scheduleRepo.findById(slotId);
    if (!slot) throw new CustomizedError("Slot no encontrado", 404);

    const student = await this.ensureStudentRow(userId);

    // Idempotency Check: user already held this slot?
    if (slot.status === SlotStatus.HELD && slot.drivingClassId) {
      const existingClass = await prisma.drivingClass.findUnique({
        where: { id: slot.drivingClassId }
      });

      // valid hold, same student, payment pending -> just return existing booking info
      if (existingClass &&
        existingClass.studentId === student.id &&
        existingClass.status === BookingStatus.PENDING_PAYMENT) {

        // Ensure hold isn't expired. If expired, we should let normal flow try to reclaim it (which might fail if logic is strictly "lt: now")
        // But actually, if it IS expired, runHoldExpiryCleanup should have run or we should handle it here.
        // If we are here, status is HELD. Let's assume valid unless expired.
        const now = new Date();
        if (slot.heldUntil && slot.heldUntil > now) {
          return {
            id: existingClass.id,
            bookingId: existingClass.id,
            drivingClass: existingClass,
            slot: slot,
            heldUntil: slot.heldUntil ?? undefined,
          };
        } else {
          // Expired. We should try to re-hold it. 
          // Proceed to normal flow which has logic for expired holds.
        }
      }
    }

    const hasPermissions = await this.instructorService.validateIfHasAllPermissions(slot.instructorId);
    if (!hasPermissions) throw new CustomizedError("Instructor no tiene permisos completos", 403);

    const instructor = await this.instructorService.getInstructorProfile(slot.instructorId) as { hourlyRate?: number } | null;
    const durationMinutes = Math.floor((slot.endTime.getTime() - slot.startTime.getTime()) / (1000 * 60));
    const hourlyRate = instructor?.hourlyRate ?? 45000;
    const amount = Math.round((hourlyRate / 60) * durationMinutes);

    const now = new Date();
    const heldUntil = new Date(now.getTime() + HOLD_MINUTES * 60 * 1000);

    const result = await prisma.$transaction(async (tx) => {
      // First, try to "clean up" if it's my own expired hold or someone else's expired hold, 
      // ensuring we can transition to HELD again.
      // The updateMany below handles:
      // 1. AVAILABLE
      // 2. OR HELD but expired (heldUntil < now)

      const holdResult = await tx.scheduleSlot.updateMany({
        where: {
          id: slotId,
          OR: [
            { status: SlotStatus.AVAILABLE },
            { status: SlotStatus.HELD, heldUntil: { lt: now } },
          ],
        },
        data: { status: SlotStatus.HELD, heldUntil },
      });
      if (holdResult.count !== 1) throw new CustomizedError("Slot no disponible o ya reservado", 409);

      const slotAfter = await tx.scheduleSlot.findUnique({ where: { id: slotId } });
      if (!slotAfter) throw new CustomizedError("Slot no encontrado", 404);

      // Si el slot venía asociado a una reserva expirada, la cerramos antes de crear la nueva.
      if (slotAfter.drivingClassId) {
        await tx.drivingClass.updateMany({
          where: {
            id: slotAfter.drivingClassId,
            status: BookingStatus.PENDING_PAYMENT,
          },
          data: { status: BookingStatus.CANCELLED },
        });
        await tx.payment.updateMany({
          where: {
            drivingClassId: slotAfter.drivingClassId,
            status: "pending",
          },
          data: { status: "cancelled" },
        });
      }

      const drivingClass = await tx.drivingClass.create({
        data: {
          studentId: student.id,
          instructorId: slotAfter.instructorId,
          date: slotAfter.startTime,
          duration: durationMinutes,
          status: BookingStatus.PENDING_PAYMENT,
          notes: null,
          amount,
          currency: "ARS",
        },
      });

      const instructorRow = await tx.instructor.findUnique({
        where: { id: slotAfter.instructorId },
        select: { commissionRate: true },
      });
      const split = splitGrossByAppCommissionPercent(amount, instructorRow?.commissionRate);

      await tx.payment.create({
        data: {
          amount,
          status: "pending",
          paymentMethod: "pending",
          drivingClassId: drivingClass.id,
          provider: "mercadopago",
          preferenceId: null,
          commissionRate: split.commissionRate,
          appCommission: split.appCommission,
          instructorAmount: split.instructorAmount,
          instructorPayoutStatus: InstructorPayoutStatus.NOT_APPLICABLE,
        },
      });

      const updatedSlot = await tx.scheduleSlot.update({
        where: { id: slotId },
        data: { drivingClassId: drivingClass.id },
      });

      return { slot: updatedSlot, drivingClass };
    });

    logger.info("Slot reservado", { slotId, drivingClassId: result.drivingClass.id });

    const bookingId = result.drivingClass.id;
    const when = formatClassWhen(result.slot.startTime);
    void (async () => {
      try {
        const instr = await prisma.instructor.findUnique({
          where: { id: result.slot.instructorId },
          select: { userId: true, user: { select: { name: true, surname: true } } },
        });
        const instrName = instr?.user
          ? `${instr.user.name ?? ""} ${instr.user.surname ?? ""}`.trim() || "tu instructor"
          : "tu instructor";
        await this.notificationService.sendPushToUser(
          userId,
          "Reserva lista",
          `Tenés una clase con ${instrName} el ${when}. Completá el pago para confirmarla.`,
          { type: "student_booking", bookingId: String(bookingId), role: "STUDENT" }
        );
        if (instr) {
          const stu = await prisma.student.findUnique({
            where: { id: result.drivingClass.studentId },
            include: { user: { select: { name: true, surname: true } } },
          });
          const stuName = stu?.user
            ? `${stu.user.name ?? ""} ${stu.user.surname ?? ""}`.trim() || "Un alumno"
            : "Un alumno";
          await this.notificationService.sendPushToUser(
            instr.userId,
            "Nueva reserva",
            `${stuName} reservó una clase el ${when}. Falta que pague para confirmar.`,
            { type: "instructor_booking", bookingId: String(bookingId), role: "INSTRUCTOR" }
          );
        }
      } catch (e) {
        logger.warn("Push reserva creada: no enviado", { error: String(e) });
      }
    })();

    return {
      id: result.drivingClass.id, // For backward compatibility
      bookingId: result.drivingClass.id,
      drivingClass: result.drivingClass, // Include full object for frontend
      slot: result.slot,
      heldUntil: result.slot.heldUntil ?? undefined,
    };
  }

  async cancelReservation(slotId: string, userId: number, userRole: string) {
    const slot = await this.scheduleRepo.findById(slotId);
    if (!slot) throw new CustomizedError("Slot no encontrado", 404);

    if (slot.status === SlotStatus.BOOKED) {
      throw new CustomizedError("No se puede cancelar un slot ya confirmado (BOOKED). Use el flujo de cancelación de clase si aplica.", 409);
    }
    if (slot.status === SlotStatus.BLOCKED) {
      throw new CustomizedError("No se puede cancelar un slot bloqueado.", 409);
    }
    if (slot.status === SlotStatus.AVAILABLE) {
      const currentSlot = await this.scheduleRepo.findById(slotId);
      return {
        slot: currentSlot ?? slot,
        booking: null,
        message: "Slot ya estaba disponible (idempotente).",
      };
    }

    if (!slot.drivingClassId) {
      const updatedSlot = await this.scheduleRepo.cancelBooking(slotId);
      return {
        slot: updatedSlot,
        booking: null,
        message: "Slot en hold sin clase asociada; liberado.",
      };
    }

    const drivingClass = await this.drivingClassService.getClassById(slot.drivingClassId);
    if (!drivingClass) {
      const updatedSlot = await this.scheduleRepo.cancelBooking(slotId);
      return {
        slot: updatedSlot,
        booking: null,
        message: "Clase no encontrada; slot liberado para mantener consistencia.",
      };
    }

    if (drivingClass.status === BookingStatus.CANCELLED) {
      const updatedSlot = await this.scheduleRepo.cancelBooking(slotId);
      return {
        slot: updatedSlot,
        booking: { status: BookingStatus.CANCELLED },
        message: "Booking ya estaba cancelado (idempotente).",
      };
    }

    if (userRole === "INSTRUCTOR") {
      const instructor = await prisma.instructor.findUnique({ where: { userId } });
      if (!instructor || slot.instructorId !== instructor.id) throw new CustomizedError("No autorizado", 403);
    } else if (userRole === "STUDENT") {
      const student = await this.ensureStudentRow(userId);
      if (drivingClass.studentId !== student.id) throw new CustomizedError("No autorizado", 403);
    } else if (userRole === "ADMIN") {
      // admin puede forzar cancelación para soporte/operación
    } else {
      throw new CustomizedError("No autorizado", 403);
    }

    await this.drivingClassService.cancelClassForUser(slot.drivingClassId, userId, userRole as Role);
    const updatedSlot = await this.scheduleRepo.findById(slotId);

    logger.info("Reserva cancelada", { slotId });
    return {
      slot: updatedSlot ?? slot,
      booking: { status: BookingStatus.CANCELLED },
    };
  }

  async deleteSlot(slotId: string, userId: number) {
    const slot = await this.scheduleRepo.findById(slotId);
    if (!slot) throw new CustomizedError("Slot no encontrado", 404);
    const instructor = await prisma.instructor.findUnique({ where: { userId } });
    if (!instructor || slot.instructorId !== instructor.id) throw new CustomizedError("No autorizado", 403);
    if (slot.status === SlotStatus.BOOKED) throw new CustomizedError("No se puede eliminar un slot reservado", 409);

    await this.scheduleRepo.delete(slotId);
    logger.info("Slot eliminado", { slotId });
  }

  /** Libera slots HELD vencidos y cancela bookings PENDING_PAYMENT asociados. Idempotente. */
  async runHoldExpiryCleanup(): Promise<void> {
    const expired = await this.scheduleRepo.findExpiredHeldSlots();
    for (const s of expired) {
      try {
        await prisma.$transaction(async (tx) => {
          if (s.drivingClassId) {
            await tx.drivingClass.updateMany({
              where: { id: s.drivingClassId, status: BookingStatus.PENDING_PAYMENT },
              data: { status: BookingStatus.CANCELLED },
            });
            await tx.payment.updateMany({
              where: { drivingClassId: s.drivingClassId, status: "pending" },
              data: { status: "cancelled" },
            });
          }
          await tx.scheduleSlot.update({
            where: { id: s.id },
            data: { status: SlotStatus.AVAILABLE, heldUntil: null, drivingClassId: null },
          });
        });
      } catch (err) {
        logger.error(`Hold expiry cleanup error for slot ${s.id}`, err instanceof Error ? err : new Error(String(err)));
      }
    }
    if (expired.length > 0) logger.info("Hold expiry cleanup", { count: expired.length });
  }
}