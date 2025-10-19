import { Router } from "express";
import EnhancedPaymentController from "./enhanced-payment.controller";
import GenericRouter from "@shared/classes/GenericRouter";
import { validate } from "@users/user.middleware";
import * as schema from "./payment.schemas";
import { authenticate } from "@auth/auth.middlewares";
import {
  paymentRateLimit,
  webhookRateLimit,
  validatePaymentAmount,
  validatePaymentMethod,
  ensureIdempotency,
  auditPaymentAction,
  validateWebhookSignature
} from "./payment-security.middleware";
import { AuditAction } from "@shared/services/AuditService";

export default class EnhancedPaymentRouter extends GenericRouter {
  constructor(private readonly controller: EnhancedPaymentController) {
    super();
  }

  init() {
    const router = super.init();

    // Payment creation with security
    router.post("/", 
      authenticate,
      paymentRateLimit,
      ensureIdempotency,
      validatePaymentAmount,
      validatePaymentMethod,
      validate(schema.createPaymentSchema),
      auditPaymentAction(AuditAction.CREATE),
      this.controller.createPayment
    );

    // Payment processing
    router.post("/:id/process", 
      authenticate,
      paymentRateLimit,
      auditPaymentAction(AuditAction.UPDATE),
      this.controller.processPayment
    );

    // Payment refund
    router.post("/:id/refund", 
      authenticate,
      paymentRateLimit,
      validate(schema.refundPaymentSchema),
      auditPaymentAction(AuditAction.UPDATE),
      this.controller.refundPayment
    );

    // Payment status check
    router.get("/:id/status", 
      authenticate,
      this.controller.checkPaymentStatus
    );

    // Payment reports (admin only)
    router.get("/reports", 
      authenticate,
      // TODO: Add admin role check middleware
      this.controller.getPaymentReport
    );

    // Webhook endpoint (no auth, but signature validation)
    router.post("/mercadopago/webhook", 
      webhookRateLimit,
      validateWebhookSignature,
      auditPaymentAction(AuditAction.UPDATE),
      this.controller.handleMercadoPagoWebhook
    );

    return router;
  }
}