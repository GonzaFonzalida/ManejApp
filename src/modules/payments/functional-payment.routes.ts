import { Router } from "express";
import FunctionalPaymentController from "./functional-payment.controller";
import PaymentService from "./payment.services";
import PrismaPaymentRepository from "./repositories/PrismaPaymentRepository";
import MercadoPagoService from "./mercadopago.service";
import { authenticate } from "@auth/auth.middlewares";
import { generalRateLimit } from "@shared/middlewares/security";
import { validateZodSchema } from "@shared/middlewares/validation";
import * as schema from "./payment.schemas";

const paymentRepo = new PrismaPaymentRepository();
const mercadoPagoService = new MercadoPagoService();
const paymentService = new PaymentService(paymentRepo, mercadoPagoService);
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

// Mercado Pago specific routes
functionalPaymentRoutes.post("/mercadopago/preference", 
  validateZodSchema(schema.createMercadoPagoPreferenceSchema), 
  controller.createMercadoPagoPreference
);

functionalPaymentRoutes.post("/mercadopago", 
  validateZodSchema(schema.createPaymentSchema), 
  controller.createPaymentWithMercadoPago
);

// Webhook endpoint (no auth required for external service)
const webhookRouter = Router();
webhookRouter.post("/mercadopago/webhook", 
  controller.handleMercadoPagoWebhook
);

export { functionalPaymentRoutes, webhookRouter };