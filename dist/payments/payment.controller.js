"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class PaymentController {
    paymentService;
    constructor(paymentService) {
        this.paymentService = paymentService;
    }
    createPayment = async (req, res, next) => {
        try {
            const payment = await this.paymentService.createPayment(req.body);
            res.status(201).json(payment);
        }
        catch (err) {
            next(err);
        }
    };
    getPayment = async (req, res, next) => {
        try {
            const payment = await this.paymentService.getPaymentById(Number(req.params.id));
            res.json(payment);
        }
        catch (err) {
            next(err);
        }
    };
    getPaymentsByDrivingClass = async (req, res, next) => {
        try {
            const payments = await this.paymentService.getPaymentsByDrivingClass(Number(req.params.drivingClassId));
            res.json(payments);
        }
        catch (err) {
            next(err);
        }
    };
    updatePaymentStatus = async (req, res, next) => {
        try {
            const payment = await this.paymentService.updatePaymentStatus(Number(req.params.id), req.body.status);
            res.json(payment);
        }
        catch (err) {
            next(err);
        }
    };
    processPayment = async (req, res, next) => {
        try {
            const payment = await this.paymentService.processPayment(Number(req.params.id));
            res.json(payment);
        }
        catch (err) {
            next(err);
        }
    };
    listPayments = async (req, res) => {
        try {
            const filter = req.query.status ? { status: req.query.status } : undefined;
            const payments = await this.paymentService.listPayments(filter);
            res.json(payments);
        }
        catch (err) {
            res.status(500).json({ error: "Error interno del servidor" });
        }
    };
    // Mercado Pago specific methods
    createMercadoPagoPreference = async (req, res, next) => {
        try {
            const preference = await this.paymentService.createMercadoPagoPreference(req.body);
            res.status(201).json(preference);
        }
        catch (err) {
            next(err);
        }
    };
    createPaymentWithMercadoPago = async (req, res, next) => {
        try {
            const payment = await this.paymentService.createPaymentWithMercadoPago(req.body);
            res.status(201).json(payment);
        }
        catch (err) {
            next(err);
        }
    };
    handleMercadoPagoWebhook = async (req, res, next) => {
        try {
            await this.paymentService.handleMercadoPagoWebhook(req.body);
            res.status(200).json({ message: "Webhook processed successfully" });
        }
        catch (err) {
            next(err);
        }
    };
}
exports.default = PaymentController;
