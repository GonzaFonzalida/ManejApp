import { Router } from "express";
import PaymentController from "./payment.controller";
import diContainer from "../DiContainer/container";
import GenericRouter from "@shared/classes/GenericRouter";
import { validate } from "src/users/user.middleware";
import * as schema from "./payment.schemas";

export default class PaymentRouter extends GenericRouter {
  constructor(private readonly controller: PaymentController) {
    super();
    const router = this.init();

    router.post("/", validate(schema.createPaymentSchema), controller.createPayment);
    router.get("/", controller.listPayments);
    router.get("/:id", controller.getPayment);
    router.get("/driving-class/:drivingClassId", controller.getPaymentsByDrivingClass);
    router.put("/:id/status", validate(schema.updatePaymentStatusSchema), controller.updatePaymentStatus);
    router.post("/:id/process", controller.processPayment);

    // Mercado Pago specific routes
    router.post("/mercadopago/preference", validate(schema.createMercadoPagoPreferenceSchema), controller.createMercadoPagoPreference);
    router.post("/mercadopago", validate(schema.createPaymentSchema), controller.createPaymentWithMercadoPago);
    router.post("/mercadopago/webhook", controller.handleMercadoPagoWebhook);
  }
}