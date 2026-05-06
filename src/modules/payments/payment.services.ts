import { PaymentRepository } from "./repositories/PaymentRepository";
import { Payment, CreatePaymentData } from "./payment.types";
import MercadoPagoService, { CreatePreferenceData, MercadoPagoPreference } from "./mercadopago.service";
import CustomizedError from "@shared/classes/CustomizedError";
import { prisma } from "@config/prismaClient";
import { BookingStatus, SlotStatus } from "@prisma/client";
import { NotificationService } from "@notifications/service";
import { logger } from "@logging/LoggerConfig";
import {
  InstructorPayoutStatus,
  splitGrossByAppCommissionPercent,
} from "./payment-commission.policy";

const MP_WEBHOOK_APPROVED = "approved";
const MP_WEBHOOK_FAILED_STATUSES = ["rejected", "cancelled", "refunded", "charged_back"];

function bookingWhenLine(d: Date): string {
  return d.toLocaleString("es-AR", {
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default class PaymentService {
  constructor(
    private paymentRepo: PaymentRepository,
    private mercadoPagoService: MercadoPagoService,
    private notificationService: NotificationService
  ) { }

  async createPayment(data: CreatePaymentData): Promise<Payment> {
    // Here you could add business logic like validating the driving class exists
    return this.paymentRepo.createPayment(data);
  }

  async getPaymentById(id: number): Promise<Payment | null> {
    const payment = await this.paymentRepo.getPaymentById(id);
    if (!payment) {
      throw new CustomizedError("Pago no encontrado", 404);
    }
    return payment;
  }

  async getPaymentsByDrivingClass(drivingClassId: number): Promise<Payment[]> {
    return this.paymentRepo.getPaymentsByDrivingClass(drivingClassId);
  }

  async getPaymentByDrivingClass(drivingClassId: number): Promise<Payment | null> {
    const payments = await this.getPaymentsByDrivingClass(drivingClassId);
    return payments[0] || null;
  }

  async updatePaymentStatus(id: number, status: string): Promise<Payment> {
    // Validate status
    if (!["pending", "paid", "failed", "cancelled"].includes(status)) {
      throw new CustomizedError("Estado de pago inválido", 400);
    }

    const payment = await this.paymentRepo.getPaymentById(id);
    if (!payment) {
      throw new CustomizedError("Pago no encontrado", 404);
    }

    return this.paymentRepo.updatePaymentStatus(id, status);
  }

  async listPayments(filter?: { status?: string }): Promise<Payment[]> {
    return this.paymentRepo.listPayments(filter);
  }

  async processPayment(id: number): Promise<Payment> {
    // Business logic for processing payment
    const payment = await this.getPaymentById(id);
    if (!payment || payment.status !== "pending") {
      throw new CustomizedError("El pago ya ha sido procesado o no existe", 400);
    }

    // Handle Mercado Pago payments
    if (payment.paymentMethod === "mercadopago") {
      if (!payment.paymentId) {
        throw new CustomizedError("No se encontró el ID de pago de Mercado Pago", 400);
      }

      // Get payment status from Mercado Pago
      const mpStatus = await this.mercadoPagoService.getPaymentStatus(payment.paymentId);
      const newStatus = this.mercadoPagoService.mapMercadoPagoStatus(mpStatus);

      return this.updatePaymentStatus(id, newStatus);
    }

    // For other payment methods, use simulated processing (for now)
    const newStatus = Math.random() > 0.1 ? "paid" : "failed"; // 90% success rate
    return this.updatePaymentStatus(id, newStatus);
  }

  // Mercado Pago specific methods
  async createMercadoPagoPreference(data: CreatePreferenceData): Promise<MercadoPagoPreference> {
    return this.mercadoPagoService.createPreference(data);
  }

  async createPaymentWithMercadoPago(data: CreatePaymentData): Promise<Payment> {
    const dc = await prisma.drivingClass.findUnique({
      where: { id: data.drivingClassId },
      include: { instructor: { select: { commissionRate: true } } },
    });
    const split = splitGrossByAppCommissionPercent(
      data.amount,
      dc?.instructor?.commissionRate
    );

    const payment = await this.paymentRepo.createPayment({
      amount: data.amount,
      paymentMethod: data.paymentMethod,
      drivingClassId: data.drivingClassId,
      provider: data.provider ?? "mercadopago",
      commissionRate: split.commissionRate,
      appCommission: split.appCommission,
      instructorAmount: split.instructorAmount,
      instructorPayoutStatus: InstructorPayoutStatus.NOT_APPLICABLE,
    });

    if (data.paymentMethod === "mercadopago") {
      try {
        const preference = await this.mercadoPagoService.createPreference({
          amount: data.amount,
          description: `Pago por clase de conducción #${data.drivingClassId}`,
          drivingClassId: data.drivingClassId,
          externalReference: payment.id.toString(),
        });

        await this.paymentRepo.updatePaymentWithMercadoPagoData(payment.id, {
          preferenceId: preference.id,
          externalReference: payment.id.toString(),
        });

        const updatedPayment = await this.getPaymentById(payment.id);
        return updatedPayment!;
      } catch (error) {
        throw error;
      }
    }

    return payment;
  }

  /**
   * M6: Create MercadoPago preference for an existing booking (DrivingClass).
   * Only the STUDENT who owns the booking can call. Validates slot HELD and heldUntil > now.
   */
  async createPreferenceForBooking(
    bookingId: number,
    userId: number,
    userRole: string
  ): Promise<{ preferenceId: string; initPoint: string }> {
    if (userRole !== "STUDENT") {
      throw new CustomizedError("Solo el estudiante dueño de la reserva puede crear la preferencia de pago", 403);
    }

    const booking = await prisma.drivingClass.findUnique({
      where: { id: bookingId },
      include: { student: true },
    });
    if (!booking) throw new CustomizedError("Reserva no encontrada", 404);
    if (booking.student.userId !== userId) {
      throw new CustomizedError("No autorizado: no es el dueño de esta reserva", 403);
    }
    if (booking.status !== BookingStatus.PENDING_PAYMENT) {
      throw new CustomizedError("La reserva no está en estado pendiente de pago", 409);
    }

    const slot = await prisma.scheduleSlot.findFirst({
      where: { drivingClassId: bookingId },
    });
    if (!slot) throw new CustomizedError("No se encontró el slot asociado a esta reserva", 404);
    if (slot.status !== SlotStatus.HELD) {
      throw new CustomizedError("El slot no está en hold. No se puede crear la preferencia.", 409);
    }
    const now = new Date();
    if (!slot.heldUntil || slot.heldUntil <= now) {
      throw new CustomizedError(
        "El tiempo de hold expiró. Por favor, vuelve a reservar el slot.",
        409
      );
    }

    const payments = await this.paymentRepo.getPaymentsByDrivingClass(bookingId);
    const payment = payments.find(
      (p) => (p.provider === "mercadopago" || !p.provider) && p.status === "pending"
    ) ?? payments[0];
    if (!payment) throw new CustomizedError("No se encontró un pago pendiente para esta reserva", 404);
    if (payment.status !== "pending") {
      throw new CustomizedError("El pago ya no está pendiente", 409);
    }

    const amount = booking.amount ?? payment.amount;

    const instructor = await prisma.instructor.findUnique({
      where: { id: booking.instructorId },
      select: { commissionRate: true },
    });
    const split = splitGrossByAppCommissionPercent(Number(amount), instructor?.commissionRate);

    const preference = await this.mercadoPagoService.createPreference({
      amount: Number(amount),
      description: `Clase de manejo - Reserva #${bookingId}`,
      drivingClassId: bookingId,
      externalReference: String(bookingId),
    });

    await this.paymentRepo.updatePaymentWithMercadoPagoData(payment.id, {
      preferenceId: preference.id,
      externalReference: String(bookingId),
      paymentMethod: "mercadopago",
      appCommission: split.appCommission,
      instructorAmount: split.instructorAmount,
      commissionRate: split.commissionRate,
    });

    return {
      preferenceId: preference.id,
      initPoint: preference.init_point ?? preference.sandbox_init_point ?? "",
    };
  }

  /**
   * Webhook MP: firma validada en middleware. Idempotente por paymentId.
   * Modelo cuenta única: persiste bruto (amount), comisión app, neto instructor y estado de liquidación interna.
   */
  async handleMercadoPagoWebhook(webhookData: any): Promise<void> {
    const { type, data } = webhookData || {};
    if (type !== "payment" || !data?.id) return;

    const mpPaymentId = String(data.id);
    let mpPayment: any;
    try {
      mpPayment = await this.mercadoPagoService.getPayment(mpPaymentId);
    } catch (e) {
      logger.warn("[MP webhook] No se pudo obtener pago en MP", { mpPaymentId, err: String(e) });
      return;
    }

    const externalRef = mpPayment.external_reference ?? mpPayment.external_reference_id;
    const bookingId = externalRef ? parseInt(String(externalRef), 10) : NaN;
    if (!Number.isInteger(bookingId)) {
      logger.warn("[MP webhook] external_reference no parseable", { externalRef });
      return;
    }

    const paymentPreview = await this.paymentRepo.getPaymentByExternalReference(String(bookingId));
    if (!paymentPreview) {
      logger.warn("[MP webhook] Pago no encontrado por external_reference", { bookingId });
      return;
    }

    const mpTxAmount =
      mpPayment.transaction_amount != null ? Number(mpPayment.transaction_amount) : null;
    if (
      mpTxAmount != null &&
      Math.abs(mpTxAmount - paymentPreview.amount) > 0.02
    ) {
      logger.warn("[MP webhook] transaction_amount MP difiere del monto registrado", {
        bookingId,
        dbAmount: paymentPreview.amount,
        mpTransactionAmount: mpTxAmount,
      });
    }

    const normalizedStatus =
      mpPayment.status === MP_WEBHOOK_APPROVED
        ? "paid"
        : MP_WEBHOOK_FAILED_STATUSES.includes(mpPayment.status)
          ? "failed"
          : "pending";

    const isApproved = mpPayment.status === MP_WEBHOOK_APPROVED;
    const isRejected = MP_WEBHOOK_FAILED_STATUSES.includes(mpPayment.status);

    const bookingBefore = await prisma.drivingClass.findUnique({
      where: { id: bookingId },
      select: { status: true, studentId: true, instructorId: true, date: true },
    });

    await prisma.$transaction(async (tx) => {
      const paymentLocked = await tx.payment.findFirst({
        where: { externalReference: String(bookingId) },
      });
      if (!paymentLocked) return;

      if (paymentLocked.status === "paid" && paymentLocked.paymentId === mpPaymentId) {
        logger.info("[MP webhook] Idempotente: mismo paymentId ya acreditado", {
          bookingId,
          mpPaymentId,
        });
        return;
      }
      if (
        paymentLocked.status === "paid" &&
        paymentLocked.paymentId &&
        paymentLocked.paymentId !== mpPaymentId
      ) {
        logger.error(
          "[MP webhook] Conflicto: reserva ya pagada con otro id MP",
          undefined,
          {},
          {
            bookingId,
            existingPaymentId: paymentLocked.paymentId,
            incoming: mpPaymentId,
          }
        );
        return;
      }

      const booking = await tx.drivingClass.findUnique({ where: { id: bookingId } });
      if (!booking) return;

      const slot = await tx.scheduleSlot.findFirst({
        where: { drivingClassId: bookingId },
      });

      let nextPaymentStatus = normalizedStatus;

      if (isApproved) {
        if (booking.status !== BookingStatus.PENDING_PAYMENT) {
          nextPaymentStatus = paymentLocked.status;
        } else {
          await tx.drivingClass.update({
            where: { id: bookingId },
            data: { status: BookingStatus.CONFIRMED },
          });
          if (slot) {
            await tx.scheduleSlot.update({
              where: { id: slot.id },
              data: { status: SlotStatus.BOOKED, heldUntil: null },
            });
          }
        }
      } else if (isRejected) {
        if (booking.status !== BookingStatus.PENDING_PAYMENT) {
          nextPaymentStatus = paymentLocked.status;
        } else {
          await tx.drivingClass.update({
            where: { id: bookingId },
            data: { status: BookingStatus.CANCELLED },
          });
          if (slot) {
            await tx.scheduleSlot.update({
              where: { id: slot.id },
              data: {
                status: SlotStatus.AVAILABLE,
                heldUntil: null,
                drivingClassId: null,
              },
            });
          }
        }
      } else if (booking.status !== BookingStatus.PENDING_PAYMENT) {
        nextPaymentStatus = paymentLocked.status;
      } else if (
        slot &&
        slot.status === SlotStatus.HELD &&
        slot.heldUntil &&
        slot.heldUntil <= new Date()
      ) {
        await tx.drivingClass.update({
          where: { id: bookingId },
          data: { status: BookingStatus.CANCELLED },
        });
        await tx.scheduleSlot.update({
          where: { id: slot.id },
          data: { status: SlotStatus.AVAILABLE, heldUntil: null, drivingClassId: null },
        });
        nextPaymentStatus = "cancelled";
      }

      const instr = await tx.instructor.findUnique({
        where: { id: booking.instructorId },
        select: { commissionRate: true },
      });
      const split = splitGrossByAppCommissionPercent(
        paymentLocked.amount,
        instr?.commissionRate
      );

      let instructorPayoutStatus: string | undefined;
      if (nextPaymentStatus === "paid") {
        instructorPayoutStatus = InstructorPayoutStatus.PENDING_INTERNAL_PAYOUT;
      } else if (nextPaymentStatus === "failed" || nextPaymentStatus === "cancelled") {
        instructorPayoutStatus = InstructorPayoutStatus.NOT_APPLICABLE;
      }

      await tx.payment.update({
        where: { id: paymentLocked.id },
        data: {
          paymentId: mpPaymentId,
          rawPayload: webhookData as object,
          status: nextPaymentStatus,
          appCommission: split.appCommission,
          instructorAmount: split.instructorAmount,
          commissionRate: split.commissionRate,
          mpTransactionAmount: mpTxAmount,
          ...(instructorPayoutStatus !== undefined
            ? { instructorPayoutStatus }
            : {}),
        },
      });
    });

    const bookingAfter = await prisma.drivingClass.findUnique({
      where: { id: bookingId },
      select: { status: true, studentId: true, instructorId: true, date: true },
    });

    if (!bookingBefore || !bookingAfter) return;

    const when = bookingWhenLine(bookingAfter.date);
    const payload = { type: "student_booking", bookingId: String(bookingId), role: "STUDENT" as const };

    if (
      isApproved &&
      bookingBefore.status === BookingStatus.PENDING_PAYMENT &&
      bookingAfter.status === BookingStatus.CONFIRMED
    ) {
      const stu = await prisma.student.findUnique({
        where: { id: bookingAfter.studentId },
        select: { userId: true },
      });
      const instr = await prisma.instructor.findUnique({
        where: { id: bookingAfter.instructorId },
        select: { userId: true, user: { select: { name: true, surname: true } } },
      });
      if (stu) {
        void this.notificationService.sendPushToUser(
          stu.userId,
          "Pago confirmado",
          `Tu clase del ${when} ya está confirmada. Te avisamos antes de que arranque.`,
          payload
        );
      }
      if (instr) {
        void this.notificationService.sendPushToUser(
          instr.userId,
          "Pago recibido",
          `Se confirmó el pago de una clase el ${when}.`,
          { type: "instructor_booking", bookingId: String(bookingId), role: "INSTRUCTOR" }
        );
      }
    } else if (
      isRejected &&
      bookingBefore.status === BookingStatus.PENDING_PAYMENT &&
      bookingAfter.status === BookingStatus.CANCELLED
    ) {
      const stu = await prisma.student.findUnique({
        where: { id: bookingAfter.studentId },
        select: { userId: true },
      });
      if (stu) {
        void this.notificationService.sendPushToUser(
          stu.userId,
          "No se pudo confirmar el pago",
          `El pago de la clase del ${when} no se acreditó. Podés volver a intentar desde la app.`,
          payload
        );
      }
    }
  }
}