import { Router } from "express";
import PaymentController from "./payment.controller";
import diContainer from "../shared/DiContainer/container";
import GenericRouter from "@shared/classes/GenericRouter";
import { validate } from "../users/user.middleware";
import * as schema from "./payment.schemas";

export default class PaymentRouter extends GenericRouter {
  constructor(private readonly controller: PaymentController) {
    super();
  }

  init() {
    const router = super.init();

    router.post("/", validate(schema.createPaymentSchema), this.controller.createPayment);
    router.get("/", this.controller.listPayments);
    router.get("/:id", this.controller.getPayment);
    router.get("/driving-class/:drivingClassId", this.controller.getPaymentsByDrivingClass);
    router.put("/:id/status", validate(schema.updatePaymentStatusSchema), this.controller.updatePaymentStatus);
    router.post("/:id/process", this.controller.processPayment);

    // Mercado Pago specific routes
    router.post("/mercadopago/preference", validate(schema.createMercadoPagoPreferenceSchema), this.controller.createMercadoPagoPreference);
    router.post("/mercadopago", validate(schema.createPaymentSchema), this.controller.createPaymentWithMercadoPago);
    router.post("/mercadopago/webhook", this.controller.handleMercadoPagoWebhook);

    return router;
  }
}