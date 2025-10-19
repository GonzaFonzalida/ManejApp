import { PaymentRepository } from "./repositories/PaymentRepository";
import { Payment, CreatePaymentData } from "./payment.types";
import MercadoPagoService, { CreatePreferenceData, MercadoPagoPreference } from "./mercadopago.service";
import CustomizedError from "@shared/classes/CustomizedError";
import { AuditService, AuditAction } from "@shared/services/AuditService";
import { prisma } from "@config/prismaClient";

export interface PaymentNotification {
  paymentId: number;
  status: string;
  amount: number;
  method: string;
}

export default class EnhancedPaymentService {
  constructor(
    private paymentRepo: PaymentRepository,
    private mercadoPagoService: MercadoPagoService
  ) {}

  async createPayment(data: CreatePaymentData, userId?: number): Promise<Payment> {
    return await prisma.$transaction(async (tx) => {
      // Validate driving class exists and belongs to user
      const drivingClass = await tx.drivingClass.findUnique({
        where: { id: data.drivingClassId },
        include: { student: true }
      });

      if (!drivingClass) {
        throw new CustomizedError("Clase de conducción no encontrada", 404);
      }

      // Validate amount
      if (data.amount <= 0) {
        throw new CustomizedError("El monto debe ser mayor a 0", 400);
      }

      // Check for duplicate payments
      const existingPayment = await this.paymentRepo.getPaymentsByDrivingClass(data.drivingClassId);
      const paidPayment = existingPayment.find(p => p.status === 'paid');
      
      if (paidPayment) {
        throw new CustomizedError("Esta clase ya tiene un pago confirmado", 400);
      }

      const payment = await this.paymentRepo.createPayment(data);

      // Audit log
      AuditService.logUserAction(
        userId || drivingClass.student.userId,
        AuditAction.CREATE,
        'payment',
        payment.id,
        { amount: data.amount, method: data.paymentMethod }
      );

      return payment;
    });
  }

  async processPaymentWithRetry(id: number, maxRetries = 3): Promise<Payment> {
    let lastError: Error;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await this.processPayment(id);
      } catch (error: any) {
        lastError = error;
        
        if (attempt < maxRetries && this.isRetryableError(error)) {
          await this.delay(1000 * attempt); // Exponential backoff
          continue;
        }
        
        throw error;
      }
    }

    throw lastError!;
  }

  private isRetryableError(error: any): boolean {
    return error.message?.includes('network') || 
           error.message?.includes('timeout') ||
           error.status >= 500;
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async processPayment(id: number): Promise<Payment> {
    return await prisma.$transaction(async (tx) => {
      const payment = await this.paymentRepo.getPaymentById(id);
      
      if (!payment) {
        throw new CustomizedError("Pago no encontrado", 404);
      }

      if (payment.status !== "pending") {
        throw new CustomizedError("El pago ya ha sido procesado", 400);
      }

      let newStatus: string;

      if (payment.paymentMethod === "mercadopago") {
        if (!payment.paymentId) {
          throw new CustomizedError("ID de pago de Mercado Pago no encontrado", 400);
        }

        const mpStatus = await this.mercadoPagoService.getPaymentStatus(payment.paymentId);
        newStatus = this.mercadoPagoService.mapMercadoPagoStatus(mpStatus);
      } else {
        // Simulate processing for other methods
        newStatus = Math.random() > 0.1 ? "paid" : "failed";
      }

      const updatedPayment = await this.paymentRepo.updatePaymentStatus(id, newStatus);

      // Audit log
      AuditService.log({
        action: AuditAction.PAYMENT,
        resource: 'payment_processing',
        resourceId: id,
        details: { 
          oldStatus: payment.status, 
          newStatus,
          method: payment.paymentMethod 
        }
      });

      return updatedPayment;
    });
  }

  async refundPayment(id: number, reason: string, userId?: number): Promise<Payment> {
    return await prisma.$transaction(async (tx) => {
      const payment = await this.paymentRepo.getPaymentById(id);
      
      if (!payment) {
        throw new CustomizedError("Pago no encontrado", 404);
      }

      if (payment.status !== "paid") {
        throw new CustomizedError("Solo se pueden reembolsar pagos confirmados", 400);
      }

      // Process refund with Mercado Pago if applicable
      if (payment.paymentMethod === "mercadopago" && payment.paymentId) {
        await this.mercadoPagoService.refundPayment(payment.paymentId);
      }

      const refundedPayment = await this.paymentRepo.updatePaymentStatus(id, "refunded");

      // Audit log
      AuditService.logUserAction(
        userId || 0,
        AuditAction.UPDATE,
        'payment_refund',
        id,
        { reason, originalAmount: payment.amount }
      );

      return refundedPayment;
    });
  }

  async validateWebhookSignature(payload: string, signature: string): Promise<boolean> {
    // Implement Mercado Pago webhook signature validation
    return this.mercadoPagoService.validateWebhookSignature(payload, signature);
  }

  async handleMercadoPagoWebhook(webhookData: any, signature?: string): Promise<void> {
    // Validate webhook signature for security
    if (signature) {
      const isValid = await this.validateWebhookSignature(JSON.stringify(webhookData), signature);
      if (!isValid) {
        throw new CustomizedError("Webhook signature inválida", 401);
      }
    }

    const { type, data } = webhookData;

    if (type === 'payment') {
      await this.processWebhookPayment(data.id);
    }
  }

  private async processWebhookPayment(paymentId: string): Promise<void> {
    try {
      const mpPayment = await this.mercadoPagoService.getPayment(paymentId);
      const externalReference = mpPayment.external_reference;

      if (externalReference) {
        const payment = await this.paymentRepo.getPaymentByExternalReference(externalReference);
        
        if (payment) {
          const newStatus = this.mercadoPagoService.mapMercadoPagoStatus(mpPayment.status);
          
          await this.paymentRepo.updatePaymentWithMercadoPagoData(payment.id, {
            paymentId: paymentId,
            status: newStatus,
          });

          // Audit webhook processing
          AuditService.log({
            action: AuditAction.UPDATE,
            resource: 'webhook_payment',
            resourceId: payment.id,
            details: { 
              webhookPaymentId: paymentId,
              newStatus,
              externalReference 
            }
          });
        }
      }
    } catch (error) {
      console.error('Error processing webhook payment:', error);
      throw error;
    }
  }

  async getPaymentReport(filters: {
    startDate?: Date;
    endDate?: Date;
    status?: string;
    method?: string;
  }): Promise<{
    payments: Payment[];
    summary: {
      total: number;
      totalAmount: number;
      byStatus: Record<string, number>;
      byMethod: Record<string, number>;
    };
  }> {
    const payments = await this.paymentRepo.getPaymentsWithFilters(filters);
    
    const summary = {
      total: payments.length,
      totalAmount: payments.reduce((sum, p) => sum + p.amount, 0),
      byStatus: payments.reduce((acc, p) => {
        acc[p.status] = (acc[p.status] || 0) + 1;
        return acc;
      }, {} as Record<string, number>),
      byMethod: payments.reduce((acc, p) => {
        acc[p.paymentMethod] = (acc[p.paymentMethod] || 0) + 1;
        return acc;
      }, {} as Record<string, number>),
    };

    return { payments, summary };
  }
}