import { PaymentRepository } from "./repositories/PaymentRepository";
import { Payment, CreatePaymentData } from "./payment.types";
import MercadoPagoService, { CreatePreferenceData, MercadoPagoPreference } from "./mercadopago.service";
import CustomizedError from "@shared/classes/CustomizedError";
import { prisma } from "@config/prismaClient";
import { BookingStatus, SlotStatus } from "@prisma/client";
import { NotificationService } from "@notifications/service";
import { logger } from "@logging/LoggerConfig";
import InstructorMpService from "@instructors/instructor-mp.service";
import {
  InstructorPayoutStatus,
  marketplaceFeeFromSplit,
  splitGrossByAppCommissionPercent,
} from "./payment-commission.policy";
import {
  canReuseMarketplacePreference,
  isLegacyPlatformPreference,
  mpAmountMatchesDb,
  mpExternalReferenceMatchesBooking,
} from "./payment-marketplace.helpers";
import { WebhookRetryableError } from "./mercadopago-webhook.errors";

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
    private notificationService: NotificationService,
    private instructorMpService: InstructorMpService
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
    if (!amount || Number(amount) <= 0) {
      throw new CustomizedError("El monto de la reserva debe ser mayor a cero", 400);
    }

    const instructor = await prisma.instructor.findUnique({
      where: { id: booking.instructorId },
      select: { id: true, commissionRate: true },
    });
    if (!instructor) {
      throw new CustomizedError("Instructor no encontrado", 404);
    }

    const split = splitGrossByAppCommissionPercent(Number(amount), instructor.commissionRate);
    const marketplaceFee = marketplaceFeeFromSplit(split);

    const { accessToken, mpCollectorId } =
      await this.instructorMpService.resolveAccessTokenForInstructor(instructor.id);

    if (isLegacyPlatformPreference(payment)) {
      logger.info("[MP marketplace] Regenerando preferencia legacy (sin marketplace_fee)", {
        bookingId,
        paymentId: payment.id,
        legacyPreferenceId: payment.preferenceId,
      });
    }

    if (canReuseMarketplacePreference(payment, mpCollectorId, marketplaceFee)) {
      return {
        preferenceId: payment.preferenceId!,
        initPoint: payment.preferenceInitPoint!,
      };
    }

    const preference = await this.mercadoPagoService.createMarketplacePreference(
      {
        amount: Number(amount),
        description: `Clase de manejo - Reserva #${bookingId}`,
        drivingClassId: bookingId,
        externalReference: String(bookingId),
        marketplaceFee,
        metadata: {
          booking_id: bookingId,
          instructor_id: booking.instructorId,
          student_id: booking.studentId,
          app_commission: split.appCommission,
          instructor_gross_amount: split.instructorAmount,
        },
      },
      accessToken
    );

    const initPoint = preference.init_point ?? preference.sandbox_init_point ?? "";

    await this.paymentRepo.updatePaymentWithMercadoPagoData(payment.id, {
      preferenceId: preference.id,
      externalReference: String(bookingId),
      paymentMethod: "mercadopago",
      appCommission: split.appCommission,
      instructorAmount: split.instructorAmount,
      commissionRate: split.commissionRate,
      marketplaceFee,
      mpCollectorId,
      preferenceInitPoint: preference.init_point ?? null,
      preferenceSandboxInitPoint: preference.sandbox_init_point ?? null,
      instructorPayoutStatus: InstructorPayoutStatus.NOT_APPLICABLE,
    });

    return {
      preferenceId: preference.id,
      initPoint,
    };
  }

  /**
   * Webhook MP: firma validada en middleware. Idempotente por paymentId.
   * Marketplace: consulta pago con token plataforma; fallback token instructor si falla.
   */
  async handleMercadoPagoWebhook(
    webhookData: any,
    context?: { correlationId?: string }
  ): Promise<void> {
    const correlationId = context?.correlationId ?? `mp-wh-${Date.now()}`;
    const { type, data } = webhookData || {};
    if (type !== "payment" || !data?.id) return;

    const mpPaymentId = String(data.id);
    let mpPayment: any;
    let instructorIdForToken: number | null = null;

    try {
      mpPayment = await this.mercadoPagoService.getPayment(mpPaymentId);
    } catch (platformErr) {
      const existingByMpId = await this.paymentRepo.getPaymentByPaymentId(mpPaymentId);
      if (existingByMpId?.drivingClassId) {
        const booking = await prisma.drivingClass.findUnique({
          where: { id: existingByMpId.drivingClassId },
          select: { instructorId: true },
        });
        instructorIdForToken = booking?.instructorId ?? null;
      }

      if (!instructorIdForToken) {
        mpPayment = await this.tryFetchMpPaymentWithPendingInstructors(mpPaymentId, correlationId);
        if (!mpPayment) {
          logger.warn("[MP webhook] No se pudo obtener pago en MP (token plataforma)", {
            correlationId,
            mpPaymentId,
            err: String(platformErr),
          });
          throw new WebhookRetryableError(
            "No se pudo consultar el pago en Mercado Pago",
            correlationId
          );
        }
      } else {
        try {
          const { accessToken } = await this.instructorMpService.resolveAccessTokenForInstructor(
            instructorIdForToken
          );
          mpPayment = await this.mercadoPagoService.getPaymentWithAccessToken(
            mpPaymentId,
            accessToken
          );
        } catch (sellerErr) {
          logger.warn("[MP webhook] No se pudo obtener pago en MP (token instructor)", {
            correlationId,
            mpPaymentId,
            instructorId: instructorIdForToken,
            err: String(sellerErr),
          });
          throw new WebhookRetryableError(
            "No se pudo consultar el pago con token del instructor",
            correlationId
          );
        }
      }
    }

    const externalRef = mpPayment.external_reference ?? mpPayment.external_reference_id;
    const bookingId = externalRef ? parseInt(String(externalRef), 10) : NaN;
    if (!Number.isInteger(bookingId)) {
      logger.warn("[MP webhook] external_reference no parseable — no se concilia", {
        correlationId,
        mpPaymentId,
        externalRef,
      });
      return;
    }

    const paymentPreview = await this.paymentRepo.getPaymentByExternalReference(String(bookingId));
    if (!paymentPreview) {
      logger.warn("[MP webhook] Pago no encontrado por external_reference — no se concilia", {
        correlationId,
        bookingId,
        mpPaymentId,
      });
      return;
    }

    if (
      !mpExternalReferenceMatchesBooking(externalRef, bookingId, paymentPreview.externalReference)
    ) {
      logger.error(
        "[MP webhook] external_reference no coincide con reserva local — abortando",
        undefined,
        {},
        { correlationId, bookingId, mpPaymentId, externalRef }
      );
      return;
    }

    if (paymentPreview.drivingClassId !== bookingId) {
      logger.error(
        "[MP webhook] drivingClassId local difiere de external_reference — abortando",
        undefined,
        {},
        {
          correlationId,
          bookingId,
          drivingClassId: paymentPreview.drivingClassId,
          mpPaymentId,
        }
      );
      return;
    }

    const mpTxAmount =
      mpPayment.transaction_amount != null ? Number(mpPayment.transaction_amount) : null;

    const isApproved = mpPayment.status === MP_WEBHOOK_APPROVED;
    const isRejected = MP_WEBHOOK_FAILED_STATUSES.includes(mpPayment.status);

    if (isApproved && !mpAmountMatchesDb(mpTxAmount, paymentPreview.amount)) {
      logger.error(
        "[MP webhook] Monto MP difiere del registrado — no se confirma reserva",
        undefined,
        {},
        {
          correlationId,
          bookingId,
          dbAmount: paymentPreview.amount,
          mpTransactionAmount: mpTxAmount,
          mpPaymentId,
        }
      );
      return;
    }

    if (
      mpTxAmount != null &&
      !mpAmountMatchesDb(mpTxAmount, paymentPreview.amount)
    ) {
      logger.warn("[MP webhook] transaction_amount MP difiere del monto registrado", {
        correlationId,
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

    const bookingBefore = await prisma.drivingClass.findUnique({
      where: { id: bookingId },
      select: { status: true, studentId: true, instructorId: true, date: true },
    });

    let wasAlreadyPaidIdempotent = false;

    await prisma.$transaction(async (tx) => {
      const paymentLocked = await tx.payment.findFirst({
        where: { externalReference: String(bookingId) },
      });
      if (!paymentLocked) return;

      if (paymentLocked.status === "paid" && paymentLocked.paymentId === mpPaymentId) {
        wasAlreadyPaidIdempotent = true;
        logger.info("[MP webhook] Idempotente: mismo paymentId ya acreditado", {
          correlationId,
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

      const isMarketplacePayment =
        paymentLocked.marketplaceFee != null && paymentLocked.mpCollectorId != null;

      let instructorPayoutStatus: string | undefined;
      if (nextPaymentStatus === "paid") {
        instructorPayoutStatus = isMarketplacePayment
          ? InstructorPayoutStatus.NOT_APPLICABLE
          : InstructorPayoutStatus.PENDING_INTERNAL_PAYOUT;
      } else if (nextPaymentStatus === "failed" || nextPaymentStatus === "cancelled") {
        instructorPayoutStatus = InstructorPayoutStatus.NOT_APPLICABLE;
      }

      await tx.payment.update({
        where: { id: paymentLocked.id },
        data: {
          paymentId: mpPaymentId,
          rawPayload: {
            ...(typeof webhookData === "object" && webhookData ? webhookData : {}),
            _reconciliation: {
              correlationId,
              mpPaymentId,
              bookingId,
              reconciledAt: new Date().toISOString(),
            },
          } as object,
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

    if (wasAlreadyPaidIdempotent) return;

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

  /** Fallback webhook: consulta pago con token del instructor de cada reserva marketplace pendiente. */
  private async tryFetchMpPaymentWithPendingInstructors(
    mpPaymentId: string,
    correlationId: string
  ): Promise<any | null> {
    const pending = await prisma.payment.findMany({
      where: {
        status: "pending",
        mpCollectorId: { not: null },
        marketplaceFee: { not: null },
      },
      select: { drivingClassId: true, externalReference: true, id: true },
      orderBy: { updatedAt: "desc" },
      take: 50,
    });

    for (const row of pending) {
      const booking = await prisma.drivingClass.findUnique({
        where: { id: row.drivingClassId },
        select: { instructorId: true, id: true },
      });
      if (!booking) continue;

      try {
        const { accessToken } = await this.instructorMpService.resolveAccessTokenForInstructor(
          booking.instructorId
        );
        const candidate = await this.mercadoPagoService.getPaymentWithAccessToken(
          mpPaymentId,
          accessToken
        );
        if (String(candidate.id) !== mpPaymentId) continue;

        const extRef = candidate.external_reference ?? candidate.external_reference_id;
        if (!mpExternalReferenceMatchesBooking(extRef, booking.id, row.externalReference)) {
          logger.warn("[MP webhook] Scan: external_reference no coincide con reserva pendiente", {
            correlationId,
            mpPaymentId,
            paymentRowId: row.id,
            candidateExternalRef: extRef,
            bookingId: booking.id,
          });
          continue;
        }

        logger.info("[MP webhook] Pago conciliado vía scan marketplace pendiente", {
          correlationId,
          mpPaymentId,
          bookingId: booking.id,
          paymentRowId: row.id,
        });
        return candidate;
      } catch {
        /* probar siguiente reserva pendiente */
      }
    }

    logger.warn("[MP webhook] Scan marketplace: sin conciliación en ventana de pendientes", {
      correlationId,
      mpPaymentId,
      pendingScanned: pending.length,
    });
    return null;
  }

  /**
   * Estado de pago MP para el cliente (preferenceId, paymentId MP o bookingId).
   * Prioriza estado en DB; solo consulta MP si sigue pending y hay paymentId.
   */
  async getMercadoPagoPaymentStatus(
    identifier: string,
    userId: number,
    userRole: string
  ): Promise<{
    status: string;
    paymentId?: string | null;
    preferenceId?: string | null;
    bookingId?: number;
    marketplace?: boolean;
  }> {
    let payment =
      (await this.paymentRepo.getPaymentByPreferenceId(identifier)) ??
      (await this.paymentRepo.getPaymentByPaymentId(identifier)) ??
      (await this.paymentRepo.getPaymentByExternalReference(identifier));

    if (!payment && /^\d+$/.test(identifier)) {
      const byId = await this.paymentRepo.getPaymentById(Number(identifier));
      payment = byId;
    }

    if (!payment) {
      throw new CustomizedError("Pago no encontrado", 404);
    }

    const booking = await prisma.drivingClass.findUnique({
      where: { id: payment.drivingClassId },
      include: { student: { select: { userId: true } } },
    });
    if (!booking) {
      throw new CustomizedError("Reserva no encontrada", 404);
    }

    const isOwner = booking.student.userId === userId;
    const isAdmin = userRole === "ADMIN";
    if (!isOwner && !isAdmin) {
      throw new CustomizedError("No autorizado", 403);
    }

    const marketplace =
      payment.marketplaceFee != null && payment.mpCollectorId != null;

    if (payment.status !== "pending" || !payment.paymentId) {
      return {
        status: payment.status,
        paymentId: payment.paymentId,
        preferenceId: payment.preferenceId,
        bookingId: payment.drivingClassId,
        marketplace,
      };
    }

    try {
      let mpPayment: any;
      try {
        mpPayment = await this.mercadoPagoService.getPayment(payment.paymentId);
      } catch {
        const { accessToken } = await this.instructorMpService.resolveAccessTokenForInstructor(
          booking.instructorId
        );
        mpPayment = await this.mercadoPagoService.getPaymentWithAccessToken(
          payment.paymentId,
          accessToken
        );
      }
      const mapped = this.mercadoPagoService.mapMercadoPagoStatus(mpPayment.status);
      return {
        status: mapped,
        paymentId: payment.paymentId,
        preferenceId: payment.preferenceId,
        bookingId: payment.drivingClassId,
        marketplace,
      };
    } catch {
      return {
        status: payment.status,
        paymentId: payment.paymentId,
        preferenceId: payment.preferenceId,
        bookingId: payment.drivingClassId,
        marketplace,
      };
    }
  }
}