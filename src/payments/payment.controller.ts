import { Request, Response } from "express";
import PaymentService from "./payment.services";
import { ExpressFunction } from "../shared/types/ExpressFunction";
import CustomizedError from "@shared/classes/CustomizedError";

export default class PaymentController {
  constructor(private paymentService: PaymentService) {}

  createPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.createPayment(req.body);
      res.status(201).json(payment);
    } catch (err) {
      next(err);
    }
  };

  getPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.getPaymentById(Number(req.params.id));
      res.json(payment);
    } catch (err) {
      next(err);
    }
  };

  getPaymentsByDrivingClass: ExpressFunction = async (req, res, next) => {
    try {
      const payments = await this.paymentService.getPaymentsByDrivingClass(
        Number(req.params.drivingClassId)
      );
      res.json(payments);
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
      res.json(payment);
    } catch (err) {
      next(err);
    }
  };

  processPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.processPayment(Number(req.params.id));
      res.json(payment);
    } catch (err) {
      next(err);
    }
  };

  listPayments = async (req: Request, res: Response) => {
    try {
      const filter = req.query.status ? { status: req.query.status as string } : undefined;
      const payments = await this.paymentService.listPayments(filter);
      res.json(payments);
    } catch (err) {
      res.status(500).json({ error: "Error interno del servidor" });
    }
  };

  // Mercado Pago specific methods
  createMercadoPagoPreference: ExpressFunction = async (req, res, next) => {
    try {
      const preference = await this.paymentService.createMercadoPagoPreference(req.body);
      res.status(201).json(preference);
    } catch (err) {
      next(err);
    }
  };

  createPaymentWithMercadoPago: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.createPaymentWithMercadoPago(req.body);
      res.status(201).json(payment);
    } catch (err) {
      next(err);
    }
  };

  handleMercadoPagoWebhook: ExpressFunction = async (req, res, next) => {
    try {
      await this.paymentService.handleMercadoPagoWebhook(req.body);
      res.status(200).json({ message: "Webhook processed successfully" });
    } catch (err) {
      next(err);
    }
  };
}