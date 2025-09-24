import { PaymentRepository } from "./repositories/PaymentRepository";
import { Payment, CreatePaymentData } from "./payment.types";
import MercadoPagoService, { CreatePreferenceData, MercadoPagoPreference } from "./mercadopago.service";
import CustomizedError from "@shared/classes/CustomizedError";

export default class PaymentService {
  constructor(
    private paymentRepo: PaymentRepository,
    private mercadoPagoService: MercadoPagoService
  ) {}

  async createPayment(data: CreatePaymentData): Promise<Payment> {
    // Here you could add business logic like validating the driving class exists
    return this.paymentRepo.createPayment(data);
  }

  async getPaymentById(id: number): Promise<Payment | null> {
    const payment = await this.paymentRepo.getPaymentById(id);
    if (!payment) {
      throw new CustomizedError("Pago no encontrado", 404);
    }
    return payment;
  }

  async getPaymentsByDrivingClass(drivingClassId: number): Promise<Payment[]> {
    return this.paymentRepo.getPaymentsByDrivingClass(drivingClassId);
  }

  async getPaymentByDrivingClass(drivingClassId: number): Promise<Payment | null> {
    const payments = await this.getPaymentsByDrivingClass(drivingClassId);
    return payments[0] || null;
  }

  async updatePaymentStatus(id: number, status: string): Promise<Payment> {
    // Validate status
    if (!["pending", "paid", "failed", "cancelled"].includes(status)) {
      throw new CustomizedError("Estado de pago inválido", 400);
    }

    const payment = await this.paymentRepo.getPaymentById(id);
    if (!payment) {
      throw new CustomizedError("Pago no encontrado", 404);
    }

    return this.paymentRepo.updatePaymentStatus(id, status);
  }

  async listPayments(filter?: { status?: string }): Promise<Payment[]> {
    return this.paymentRepo.listPayments(filter);
  }

  async processPayment(id: number): Promise<Payment> {
    // Business logic for processing payment
    const payment = await this.getPaymentById(id);
    if (!payment || payment.status !== "pending") {
      throw new CustomizedError("El pago ya ha sido procesado o no existe", 400);
    }

    // Handle Mercado Pago payments
    if (payment.paymentMethod === "mercadopago") {
      if (!payment.paymentId) {
        throw new CustomizedError("No se encontró el ID de pago de Mercado Pago", 400);
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
  async createMercadoPagoPreference(data: CreatePreferenceData): Promise<MercadoPagoPreference> {
    return this.mercadoPagoService.createPreference(data);
  }

  async createPaymentWithMercadoPago(data: CreatePaymentData): Promise<Payment> {
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
        return updatedPayment!;
      } catch (error) {
        // If preference creation fails, delete the payment and throw error
        // Note: In a real app, you might want to handle this differently
        throw error;
      }
    }

    return payment;
  }

  async handleMercadoPagoWebhook(webhookData: any): Promise<void> {
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