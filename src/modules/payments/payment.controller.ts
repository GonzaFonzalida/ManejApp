import { Request, Response } from "express";
import PaymentService from "./payment.services";
import CommissionEnhancedService from "./commission-enhanced.service";
import { ExpressFunction } from "@sharedTypes/ExpressFunction";
import CustomizedError from "@shared/classes/CustomizedError";

export default class PaymentController {
  constructor(
    private paymentService: PaymentService,
    private commissionService: CommissionEnhancedService
  ) {}

  /**
   * @swagger
   * /payments:
   *   post:
   *     summary: Create a new payment
   *     tags: [Payments]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - amount
   *               - paymentMethod
   *               - drivingClassId
   *             properties:
   *               amount:
   *                 type: number
   *                 minimum: 0
   *               paymentMethod:
   *                 type: string
   *                 enum: [cash, card, transfer, mercadopago]
   *               drivingClassId:
   *                 type: integer
   *                 minimum: 1
   *               preferenceId:
   *                 type: string
   *               paymentId:
   *                 type: string
   *               externalReference:
   *                 type: string
   *     responses:
   *       201:
   *         description: Payment created successfully
   *       500:
   *         description: Internal server error
   */
  createPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.createPayment(req.body);
      res.status(201).json(payment);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /payments/{id}:
   *   get:
   *     summary: Get payment by ID
   *     tags: [Payments]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Payment ID
   *     responses:
   *       200:
   *         description: Payment retrieved successfully
   *       404:
   *         description: Payment not found
   *       500:
   *         description: Internal server error
   */
  getPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.getPaymentById(Number(req.params.id));
      res.json(payment);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /payments/driving-class/{drivingClassId}:
   *   get:
   *     summary: Get payments by driving class ID
   *     tags: [Payments]
   *     parameters:
   *       - in: path
   *         name: drivingClassId
   *         required: true
   *         schema:
   *           type: integer
   *         description: Driving class ID
   *     responses:
   *       200:
   *         description: Payments retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: array
   *               items:
   *                 type: object
   *       500:
   *         description: Internal server error
   */
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

  /**
   * @swagger
   * /payments/{id}/status:
   *   put:
   *     summary: Update payment status
   *     tags: [Payments]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Payment ID
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - status
   *             properties:
   *               status:
   *                 type: string
   *                 enum: [pending, paid, failed]
   *     responses:
   *       200:
   *         description: Payment status updated successfully
   *       500:
   *         description: Internal server error
   */
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

  /**
   * @swagger
   * /payments/{id}/process:
   *   post:
   *     summary: Process payment
   *     tags: [Payments]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Payment ID
   *     responses:
   *       200:
   *         description: Payment processed successfully
   *       500:
   *         description: Internal server error
   */
  processPayment: ExpressFunction = async (req, res, next) => {
    try {
      const payment = await this.paymentService.processPayment(Number(req.params.id));
      res.json(payment);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /payments:
   *   get:
   *     summary: Get all payments
   *     tags: [Payments]
   *     parameters:
   *       - in: query
   *         name: status
   *         schema:
   *           type: string
   *         description: Filter by payment status
   *     responses:
   *       200:
   *         description: Payments retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: array
   *               items:
   *                 type: object
   *       500:
   *         description: Internal server error
   */
  listPayments: ExpressFunction = async (req, res, next) => {
    try {
      const filter = req.query.status ? { status: req.query.status as string } : undefined;
      const payments = await this.paymentService.listPayments(filter);
      res.json(payments);
    } catch (err) {
      next(err);
    }
  };

  // Mercado Pago specific methods
  /**
   * @swagger
   * /payments/mercadopago/preference:
   *   post:
   *     summary: Create Mercado Pago preference
   *     tags: [Payments]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - amount
   *               - drivingClassId
   *               - description
   *             properties:
   *               amount:
   *                 type: number
   *                 minimum: 0
   *               drivingClassId:
   *                 type: integer
   *                 minimum: 1
   *               description:
   *                 type: string
   *                 minLength: 1
   *                 maxLength: 255
   *     responses:
   *       201:
   *         description: Mercado Pago preference created successfully
   *       500:
   *         description: Internal server error
   */
  createMercadoPagoPreference: ExpressFunction = async (req, res, next) => {
    try {
      const preference = await this.paymentService.createMercadoPagoPreference(req.body);
      res.status(201).json(preference);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /payments/mercadopago:
   *   post:
   *     summary: Create payment with Mercado Pago
   *     tags: [Payments]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - amount
   *               - paymentMethod
   *               - drivingClassId
   *             properties:
   *               amount:
   *                 type: number
   *                 minimum: 0
   *               paymentMethod:
   *                 type: string
   *                 enum: [cash, card, transfer, mercadopago]
   *               drivingClassId:
   *                 type: integer
   *                 minimum: 1
   *               preferenceId:
   *                 type: string
   *               paymentId:
   *                 type: string
   *               externalReference:
   *                 type: string
   *     responses:
   *       201:
   *         description: Payment created with Mercado Pago successfully
   *       500:
   *         description: Internal server error
   */
  createPaymentWithMercadoPago: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      const payment = await this.commissionService.createPaymentWithCommission(req.body, userId);
      res.status(201).json(payment);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /payments/mercadopago/webhook:
   *   post:
   *     summary: Handle Mercado Pago webhook
   *     tags: [Payments]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - id
   *               - type
   *               - data
   *             properties:
   *               id:
   *                 type: string
   *               type:
   *                 type: string
   *               data:
   *                 type: object
   *                 properties:
   *                   id:
   *                     type: string
   *     responses:
   *       200:
   *         description: Webhook processed successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 message:
   *                   type: string
   *       500:
   *         description: Internal server error
   */
  handleMercadoPagoWebhook: ExpressFunction = async (req, res, next) => {
    try {
      await this.paymentService.handleMercadoPagoWebhook(req.body);
      res.status(200).json({ message: "Webhook processed successfully" });
    } catch (err) {
      next(err);
    }
  };
}