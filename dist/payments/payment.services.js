"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const CustomizedError_1 = __importDefault(require("../shared/classes/CustomizedError"));
class PaymentService {
    paymentRepo;
    mercadoPagoService;
    constructor(paymentRepo, mercadoPagoService) {
        this.paymentRepo = paymentRepo;
        this.mercadoPagoService = mercadoPagoService;
    }
    async createPayment(data) {
        // Here you could add business logic like validating the driving class exists
        return this.paymentRepo.createPayment(data);
    }
    async getPaymentById(id) {
        const payment = await this.paymentRepo.getPaymentById(id);
        if (!payment) {
            throw new CustomizedError_1.default("Pago no encontrado", 404);
        }
        return payment;
    }
    async getPaymentsByDrivingClass(drivingClassId) {
        return this.paymentRepo.getPaymentsByDrivingClass(drivingClassId);
    }
    async updatePaymentStatus(id, status) {
        // Validate status
        if (!["pending", "paid", "failed"].includes(status)) {
            throw new CustomizedError_1.default("Estado de pago inválido", 400);
        }
        const payment = await this.paymentRepo.getPaymentById(id);
        if (!payment) {
            throw new CustomizedError_1.default("Pago no encontrado", 404);
        }
        return this.paymentRepo.updatePaymentStatus(id, status);
    }
    async listPayments(filter) {
        return this.paymentRepo.listPayments(filter);
    }
    async processPayment(id) {
        // Business logic for processing payment
        const payment = await this.getPaymentById(id);
        if (!payment || payment.status !== "pending") {
            throw new CustomizedError_1.default("El pago ya ha sido procesado o no existe", 400);
        }
        // Handle Mercado Pago payments
        if (payment.paymentMethod === "mercadopago") {
            if (!payment.paymentId) {
                throw new CustomizedError_1.default("No se encontró el ID de pago de Mercado Pago", 400);
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
    async createMercadoPagoPreference(data) {
        return this.mercadoPagoService.createPreference(data);
    }
    async createPaymentWithMercadoPago(data) {
        // Create the payment record first
        const payment = await this.createPayment(data);
        // If it's a Mercado Pago payment, create the preference
        if (data.paymentMethod === "mercadopago") {
            try {
                const preference = await this.mercadoPagoService.createPreference({
                    amount: data.amount,
                    description: `Pago por clase de conducción #${data.drivingClassId}`,
                    externalReference: payment.id.toString(),
                });
                // Update the payment with Mercado Pago data
                await this.paymentRepo.updatePaymentWithMercadoPagoData(payment.id, {
                    preferenceId: preference.id,
                    externalReference: payment.id.toString(),
                });
                // Return updated payment
                const updatedPayment = await this.getPaymentById(payment.id);
                return updatedPayment;
            }
            catch (error) {
                // If preference creation fails, delete the payment and throw error
                // Note: In a real app, you might want to handle this differently
                throw error;
            }
        }
        return payment;
    }
    async handleMercadoPagoWebhook(webhookData) {
        const { type, data } = webhookData;
        if (type === 'payment') {
            const paymentId = data.id;
            const mpPayment = await this.mercadoPagoService.getPayment(paymentId.toString());
            // Find our payment by external reference
            const externalReference = mpPayment.external_reference;
            if (externalReference) {
                const payment = await this.paymentRepo.getPaymentByExternalReference(externalReference);
                if (payment) {
                    const newStatus = this.mercadoPagoService.mapMercadoPagoStatus(mpPayment.status);
                    await this.paymentRepo.updatePaymentWithMercadoPagoData(payment.id, {
                        paymentId: paymentId.toString(),
                        status: newStatus,
                    });
                }
            }
        }
    }
}
exports.default = PaymentService;
