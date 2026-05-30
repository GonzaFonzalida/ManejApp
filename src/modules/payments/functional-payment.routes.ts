import { Router } from "express";
import FunctionalPaymentController from "./functional-payment.controller";
import PaymentService from "./payment.services";
import diContainer from "@shared/DiContainer/container";
import { authenticate, requireRole } from "@auth/auth.middlewares";
import { generalRateLimit } from "@shared/middlewares/security";
import { validateZodSchema } from "@shared/middlewares/validation";
import * as schema from "./payment.schemas";
import { webhookRateLimit } from "./payment-security.middleware";
import { mercadoPagoWebhookSignatureMiddleware } from "./mercadopago-webhook.middleware";

const paymentService = diContainer.resolve<PaymentService>("paymentService");
const controller = new FunctionalPaymentController(paymentService);

const functionalPaymentRoutes = Router();

// Apply security middleware
functionalPaymentRoutes.use(authenticate);
functionalPaymentRoutes.use(generalRateLimit);

// Basic payment operations
functionalPaymentRoutes.post("/",
  validateZodSchema(schema.createPaymentSchema),
  controller.createPayment
);

functionalPaymentRoutes.get("/",
  controller.listPayments
);

functionalPaymentRoutes.get("/:id",
  controller.getPayment
);

functionalPaymentRoutes.get("/driving-class/:drivingClassId",
  controller.getPaymentsByDrivingClass
);

functionalPaymentRoutes.put("/:id/status",
  validateZodSchema(schema.updatePaymentStatusSchema),
  controller.updatePaymentStatus
);

functionalPaymentRoutes.post("/:id/process",
  controller.processPayment
);

// Mercado Pago: create preference by bookingId (M6). Auth + STUDENT only.
functionalPaymentRoutes.post("/mercadopago/preference",
  requireRole("STUDENT"),
  validateZodSchema(schema.createPreferenceByBookingSchema),
  controller.createPreferenceForBooking
);

// Estado post-pago (preferenceId, paymentId MP o bookingId). Antes de /:id
functionalPaymentRoutes.get("/mercadopago/status/:identifier",
  controller.getMercadoPagoPaymentStatus
);

// Fix for frontend calling /booking/:bookingId/preference
functionalPaymentRoutes.post("/booking/:bookingId/preference",
  requireRole("STUDENT"),
  (req, res, next) => {
    // Map URL param to body for validation schema
    if (req.params.bookingId) {
      req.body.bookingId = parseInt(req.params.bookingId, 10);
    }
    next();
  },
  validateZodSchema(schema.createPreferenceByBookingSchema),
  controller.createPreferenceForBooking
);

functionalPaymentRoutes.post("/mercadopago",
  validateZodSchema(schema.createPaymentSchema),
  controller.createPaymentWithMercadoPago
);

// Webhook endpoint (no auth required for external service)
const webhookRouter = Router();
webhookRouter.post("/mercadopago/webhook",
  webhookRateLimit,
  mercadoPagoWebhookSignatureMiddleware,
  controller.handleMercadoPagoWebhook
);

export { functionalPaymentRoutes, webhookRouter };