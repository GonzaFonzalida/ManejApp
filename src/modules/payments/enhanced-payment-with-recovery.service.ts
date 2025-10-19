import { PaymentRepository } from "./repositories/PaymentRepository";
import { Payment, CreatePaymentData } from "./payment.types";
import EnhancedMercadoPagoService from "./enhanced-mercadopago.service";
import PaymentRecoveryService from "./payment-recovery.service";
import CustomizedError from "@shared/classes/CustomizedError";
import { AuditService, AuditAction } from "@shared/services/AuditService";
import { prisma } from "@config/prismaClient";

export default class EnhancedPaymentWithRecoveryService {
  constructor(
    private paymentRepo: PaymentRepository,
    private mercadoPagoService: EnhancedMercadoPagoService,
    private recoveryService: PaymentRecoveryService
  ) {}

  async createPayment(data: CreatePaymentData, userId?: number): Promise<Payment> {
    return await prisma.$transaction(async (tx) => {
      let payment: Payment;
      
      try {
        // Log inicio del proceso
        const tempId = Date.now(); // ID temporal para logging
        await this.recoveryService.logPaymentStep(tempId, 'payment_creation_started', 'started', data);

        // Validaciones
        const drivingClass = await tx.drivingClass.findUnique({
          where: { id: data.drivingClassId },
          include: { student: true }
        });

        if (!drivingClass) {
          throw new CustomizedError("Clase de conducción no encontrada", 404);
        }

        if (data.amount <= 0) {
          throw new CustomizedError("El monto debe ser mayor a 0", 400);
        }

        // Verificar pagos duplicados
        const existingPayment = await this.paymentRepo.getPaymentsByDrivingClass(data.drivingClassId);
        const paidPayment = existingPayment.find(p => p.status === 'paid');
        
        if (paidPayment) {
          throw new CustomizedError("Esta clase ya tiene un pago confirmado", 400);
        }

        // Crear pago en estado "processing"
        payment = await this.paymentRepo.createPayment({
          ...data,
          status: 'processing' // Estado temporal durante creación
        });

        await this.recoveryService.logPaymentStep(payment.id, 'payment_created', 'completed', { paymentId: payment.id });

        // Si es Mercado Pago, crear preferencia
        if (data.paymentMethod === 'mercadopago') {
          await this.recoveryService.logPaymentStep(payment.id, 'mp_preference_creation_started', 'started');

          try {
            const preference = await this.mercadoPagoService.createPreference({
              amount: data.amount,
              description: `Clase de conducción #${data.drivingClassId}`,
              externalReference: payment.id.toString(),
            });

            await this.paymentRepo.updatePaymentWithMercadoPagoData(payment.id, {
              preferenceId: preference.id,
              externalReference: payment.id.toString(),
            });

            await this.recoveryService.logPaymentStep(payment.id, 'mp_preference_created', 'completed', {
              preferenceId: preference.id
            });

          } catch (mpError: any) {
            await this.recoveryService.logPaymentStep(payment.id, 'mp_preference_creation_failed', 'failed', {}, mpError.message);
            
            // Marcar pago como failed pero mantener registro
            await this.paymentRepo.updatePaymentStatus(payment.id, 'failed');
            throw new CustomizedError("Error al crear preferencia de Mercado Pago", 500);
          }
        }

        // Cambiar estado a "pending" al completar exitosamente
        payment = await this.paymentRepo.updatePaymentStatus(payment.id, 'pending');
        
        await this.recoveryService.logPaymentStep(payment.id, 'payment_creation_completed', 'completed', {
          finalStatus: 'pending'
        });

        // Audit log
        AuditService.logUserAction(
          userId || drivingClass.student.userId,
          AuditAction.CREATE,
          'payment',
          payment.id,
          { amount: data.amount, method: data.paymentMethod }
        );

        return payment;

      } catch (error: any) {
        // Si ya tenemos un payment ID, logear el error
        if (payment?.id) {
          await this.recoveryService.logPaymentStep(payment.id, 'payment_creation_error', 'failed', {}, error.message);
        }
        throw error;
      }
    }, {
      timeout: 30000, // 30 segundos timeout
      isolationLevel: 'ReadCommitted'
    });
  }

  async processPayment(id: number): Promise<Payment> {
    return await prisma.$transaction(async (tx) => {
      try {
        await this.recoveryService.logPaymentStep(id, 'payment_processing_started', 'started');

        const payment = await this.paymentRepo.getPaymentById(id);
        
        if (!payment) {
          throw new CustomizedError("Pago no encontrado", 404);
        }

        if (!['pending', 'processing'].includes(payment.status)) {
          throw new CustomizedError("El pago ya ha sido procesado", 400);
        }

        // Marcar como processing
        await this.paymentRepo.updatePaymentStatus(id, 'processing');

        let newStatus: string;

        if (payment.paymentMethod === 'mercadopago') {
          await this.recoveryService.logPaymentStep(id, 'mp_status_check_started', 'started');

          if (!payment.paymentId) {
            throw new CustomizedError("ID de pago de Mercado Pago no encontrado", 400);
          }

          const mpStatus = await this.mercadoPagoService.getPaymentStatus(payment.paymentId);
          newStatus = this.mercadoPagoService.mapMercadoPagoStatus(mpStatus);

          await this.recoveryService.logPaymentStep(id, 'mp_status_checked', 'completed', {
            mpStatus,
            mappedStatus: newStatus
          });
        } else {
          // Simular procesamiento para otros métodos
          newStatus = Math.random() > 0.1 ? "paid" : "failed";
          
          await this.recoveryService.logPaymentStep(id, 'local_processing_completed', 'completed', {
            simulatedStatus: newStatus
          });
        }

        const updatedPayment = await this.paymentRepo.updatePaymentStatus(id, newStatus);

        await this.recoveryService.logPaymentStep(id, 'payment_processing_completed', 'completed', {
          finalStatus: newStatus
        });

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

      } catch (error: any) {
        await this.recoveryService.logPaymentStep(id, 'payment_processing_error', 'failed', {}, error.message);
        
        // En caso de error, marcar como failed en lugar de dejar en processing
        try {
          await this.paymentRepo.updatePaymentStatus(id, 'failed');
        } catch (updateError) {
          console.error('Error updating payment status to failed:', updateError);
        }
        
        throw error;
      }
    }, {
      timeout: 60000, // 60 segundos para procesamiento
      isolationLevel: 'ReadCommitted'
    });
  }

  // Método para recuperar pagos automáticamente
  async runRecoveryProcess(): Promise<void> {
    try {
      await this.recoveryService.recoverFailedPayments();
    } catch (error) {
      console.error('Error in recovery process:', error);
    }
  }

  // Verificar integridad de un pago específico
  async verifyPayment(paymentId: number): Promise<any> {
    return await this.recoveryService.verifyPaymentIntegrity(paymentId);
  }

  // Obtener historial de recuperación
  async getPaymentHistory(paymentId: number): Promise<any> {
    return await this.recoveryService.getRecoveryHistory(paymentId);
  }
}