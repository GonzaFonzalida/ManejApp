import { Request, Response } from "express";
import PaymentService from "./payment.services";
import { ExpressFunction } from "@sharedTypes/ExpressFunction";
import { ResponseFormatter } from "@shared/utils/responseFormatter";
import { WebhookRetryableError } from "./mercadopago-webhook.errors";
import { logger } from "@logging/LoggerConfig";

export default class FunctionalPaymentController {
  constructor(private paymentService: PaymentService) { }

  createPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.createPayment(req.body);
      return ResponseFormatter.created(res, payment, 'Pago creado exitosamente');
    } catch (err) {
      next(err);
    }
  };

  getPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.getPaymentById(Number(req.params.id));
      return ResponseFormatter.success(res, payment, 'Pago obtenido exitosamente');
    } catch (err) {
      next(err);
    }
  };

  getPaymentsByDrivingClass: ExpressFunction = async (req, res, next) => {
    try {
      const payments = await this.paymentService.getPaymentsByDrivingClass(
        Number(req.params.drivingClassId)
      );
      return ResponseFormatter.success(res, payments, 'Pagos obtenidos exitosamente');
    } catch (err) {
      next(err);
    }
  };

  updatePaymentStatus: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.updatePaymentStatus(
        Number(req.params.id),
        req.body.status
      );
      return ResponseFormatter.success(res, payment, 'Estado del pago actualizado exitosamente');
    } catch (err) {
      next(err);
    }
  };

  processPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.processPayment(Number(req.params.id));
      return ResponseFormatter.success(res, payment, 'Pago procesado exitosamente');
    } catch (err) {
      next(err);
    }
  };

  listPayments: ExpressFunction = async (req, res, next) => {
    try {
      const filter = req.query.status ? { status: req.query.status as string } : undefined;
      const payments = await this.paymentService.listPayments(filter);
      return ResponseFormatter.success(res, payments, 'Pagos listados exitosamente');
    } catch (err) {
      next(err);
    }
  };

  // Mercado Pago specific methods
  createMercadoPagoPreference: ExpressFunction = async (req, res, next) => {
    try {
      const preference = await this.paymentService.createMercadoPagoPreference(req.body);
      return ResponseFormatter.created(res, preference, 'Preferencia de Mercado Pago creada exitosamente');
    } catch (err) {
      next(err);
    }
  };

  /** M6: Create preference by bookingId. Auth required, STUDENT only. Returns { preferenceId, initPoint }. */
  createPreferenceForBooking: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      const userRole = (req as any).user?.role;
      if (!userId || !userRole) {
        return ResponseFormatter.error(res, 'No autorizado', 401);
      }
      // Accept both bookingId and drivingClassId for backward compatibility
      const { bookingId, drivingClassId } = req.body;
      const classId = bookingId || drivingClassId;
      const result = await this.paymentService.createPreferenceForBooking(classId, userId, userRole);
      return ResponseFormatter.created(res, result, 'Preferencia creada');
    } catch (err) {
      next(err);
    }
  };

  createPaymentWithMercadoPago: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.createPaymentWithMercadoPago(req.body);
      return ResponseFormatter.created(res, payment, 'Pago con Mercado Pago creado exitosamente');
    } catch (err) {
      next(err);
    }
  };

  handleMercadoPagoWebhook: ExpressFunction = async (req, res) => {
    const correlationId =
      (req.headers["x-request-id"] as string | undefined) ?? `mp-wh-${Date.now()}`;
    try {
      await this.paymentService.handleMercadoPagoWebhook(req.body, { correlationId });
      return res.status(200).json({ ok: true, correlationId });
    } catch (err) {
      if (err instanceof WebhookRetryableError) {
        logger.warn("[MP webhook] Respuesta 503 para reintento MP", {
          correlationId: err.correlationId ?? correlationId,
          message: err.message,
        });
        return res.status(503).json({
          ok: false,
          retry: true,
          correlationId: err.correlationId ?? correlationId,
        });
      }
      logger.error("[MP webhook] Error no reintetable", undefined, {}, {
        correlationId,
        message: err instanceof Error ? err.message : String(err),
      });
      return res.status(200).json({ ok: true, correlationId });
    }
  };

  getMercadoPagoPaymentStatus: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      const userRole = (req as any).user?.role;
      if (!userId || !userRole) {
        return ResponseFormatter.error(res, 'No autorizado', 401);
      }
      const result = await this.paymentService.getMercadoPagoPaymentStatus(
        req.params.identifier,
        userId,
        userRole
      );
      return ResponseFormatter.success(res, result, 'Estado de pago obtenido');
    } catch (err) {
      next(err);
    }
  };
}