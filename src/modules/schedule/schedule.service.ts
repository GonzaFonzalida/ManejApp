import { ScheduleSlotRepository } from "./repositories/ScheduleSlotRepository";
import  InstructorService from "../instructors/instructor.services";
import { DrivingClassService } from "../drivingClass/services";
import  PaymentService  from "../payments/payment.services";
import CustomizedError from "@shared/classes/CustomizedError";
import { logger } from "@shared/logging/LoggerConfig";

export class ScheduleService {
  constructor(
    private scheduleRepo: ScheduleSlotRepository,
    private instructorService: InstructorService,
    private drivingClassService: DrivingClassService,
    private paymentService: PaymentService
  ) {}

  async createSlot(instructorId: number, startTime: Date, endTime: Date) {
    // Validar que el instructor existe
    const instructor = await this.instructorService.getInstructorProfile(instructorId);
    if (!instructor) throw new CustomizedError("Instructor no encontrado", 404);

    // Validar fechas
    if (startTime >= endTime) throw new CustomizedError("La hora de fin debe ser posterior a la de inicio", 400);

    // Validar que no se superponga con otros slots del instructor
    const existingSlots = await this.scheduleRepo.findByInstructor(instructorId);
    const overlap = existingSlots.some(slot =>
      (startTime < slot.endTime && endTime > slot.startTime)
    );
    if (overlap) throw new CustomizedError("El slot se superpone con uno existente", 409);

    const slot = await this.scheduleRepo.create({
      instructorId,
      startTime,
      endTime,
      isBooked: false,
      drivingClassId: null,
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

  async reserveSlot(slotId: string, studentId: number) {
    const slot = await this.scheduleRepo.findById(slotId);
    if (!slot) throw new CustomizedError("Slot no encontrado", 404);
    if (slot.isBooked) throw new CustomizedError("Slot ya reservado", 409);

    // Validar que el instructor tenga permisos completos
    const hasPermissions = await this.instructorService.validateIfHasAllPermissions(slot.instructorId);
    if (!hasPermissions) throw new CustomizedError("Instructor no tiene permisos completos", 403);

    // Crear DrivingClass
    const drivingClass = await this.drivingClassService.create({
      studentId,
      instructorId: slot.instructorId,
      date: slot.startTime,
      duration: Math.floor((slot.endTime.getTime() - slot.startTime.getTime()) / (1000 * 60)), // minutos
      status: "scheduled",
      notes: null,
    });

    // Marcar slot como booked
    const updatedSlot = await this.scheduleRepo.bookSlot(slotId, drivingClass.id);

    // Iniciar pago
    await this.paymentService.createPayment({
      drivingClassId: drivingClass.id,
      amount: 100, // ejemplo
      paymentMethod: "pending",
    });

    logger.info("Slot reservado", { slotId, drivingClassId: drivingClass.id });
    return { slot: updatedSlot, drivingClass };
  }

  async cancelReservation(slotId: string, userId: number, userRole: string) {
    const slot = await this.scheduleRepo.findById(slotId);
    if (!slot) throw new CustomizedError("Slot no encontrado", 404);
    if (!slot.isBooked) throw new CustomizedError("Slot no está reservado", 400);

    // Obtener la clase para verificar permisos
    const drivingClass = await this.drivingClassService.getClassById(slot.drivingClassId as number);
    if (!drivingClass) throw new CustomizedError("Clase no encontrada", 404);

    // Verificar permisos: instructor del slot o estudiante de la clase
    if (userRole === "INSTRUCTOR" && slot.instructorId !== userId) {
      throw new CustomizedError("No autorizado", 403);
    }
    if (userRole === "STUDENT" && drivingClass.studentId !== userId) {
      throw new CustomizedError("No autorizado", 403);
    }

    // Cancelar pago si existe
    if (slot.drivingClassId) {
      const payment = await this.paymentService.getPaymentByDrivingClass(slot.drivingClassId);
      if (payment) {
        await this.paymentService.updatePaymentStatus(payment.id, "cancelled");
      }
    }

    // Cancelar clase
    await this.drivingClassService.cancelClass(slot.drivingClassId as number);

    // Liberar slot
    const updatedSlot = await this.scheduleRepo.cancelBooking(slotId);

    logger.info("Reserva cancelada", { slotId });
    return updatedSlot;
  }

  async deleteSlot(slotId: string, instructorId: number) {
    const slot = await this.scheduleRepo.findById(slotId);
    if (!slot) throw new CustomizedError("Slot no encontrado", 404);
    if (slot.instructorId !== instructorId) throw new CustomizedError("No autorizado", 403);
    if (slot.isBooked) throw new CustomizedError("No se puede eliminar un slot reservado", 409);

    await this.scheduleRepo.delete(slotId);
    logger.info("Slot eliminado", { slotId });
  }
}