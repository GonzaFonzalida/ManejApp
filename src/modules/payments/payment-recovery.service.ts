import { prisma } from '@config/prismaClient';
import { PaymentRepository } from './repositories/PaymentRepository';
import EnhancedMercadoPagoService from './enhanced-mercadopago.service';
import { AuditService, AuditAction } from '@shared/services/AuditService';

export interface PaymentRecoveryLog {
  id: string;
  paymentId: number;
  step: string;
  status: 'started' | 'completed' | 'failed';
  data: any;
  error?: string;
  timestamp: Date;
}

export default class PaymentRecoveryService {
  constructor(
    private paymentRepo: PaymentRepository,
    private mercadoPagoService: EnhancedMercadoPagoService
  ) {}

  // Log cada paso del proceso de pago
  async logPaymentStep(paymentId: number, step: string, status: 'started' | 'completed' | 'failed', data?: any, error?: string): Promise<void> {
    try {
      await prisma.$executeRaw`
        INSERT INTO payment_recovery_logs (payment_id, step, status, data, error, timestamp)
        VALUES (${paymentId}, ${step}, ${status}, ${JSON.stringify(data || {})}, ${error}, NOW())
      `;
    } catch (err) {
      console.error('Error logging payment step:', err);
    }
  }

  // Recuperar pagos que fallaron en proceso
  async recoverFailedPayments(): Promise<void> {
    // Buscar pagos en estado "processing" por más de 10 minutos
    const stuckPayments = await prisma.$queryRaw<any[]>`
      SELECT p.*, prl.step, prl.data 
      FROM payments p
      LEFT JOIN payment_recovery_logs prl ON p.id = prl.payment_id
      WHERE p.status = 'processing' 
      AND p.updated_at < NOW() - INTERVAL '10 minutes'
      ORDER BY p.id, prl.timestamp DESC
    `;

    for (const payment of stuckPayments) {
      await this.recoverSinglePayment(payment);
    }
  }

  private async recoverSinglePayment(payment: any): Promise<void> {
    try {
      await this.logPaymentStep(payment.id, 'recovery_started', 'started', { originalStatus: payment.status });

      if (payment.paymentMethod === 'mercadopago' && payment.paymentId) {
        // Verificar estado real en Mercado Pago
        const mpStatus = await this.mercadoPagoService.getPaymentStatus(payment.paymentId);
        const newStatus = this.mercadoPagoService.mapMercadoPagoStatus(mpStatus);

        if (newStatus !== payment.status) {
          await this.paymentRepo.updatePaymentStatus(payment.id, newStatus);
          
          await this.logPaymentStep(payment.id, 'recovery_completed', 'completed', {
            recoveredStatus: newStatus,
            mpStatus
          });

          AuditService.log({
            action: AuditAction.UPDATE,
            resource: 'payment_recovery',
            resourceId: payment.id,
            details: { 
              originalStatus: payment.status,
              recoveredStatus: newStatus,
              method: 'mercadopago_sync'
            }
          });
        }
      } else {
        // Para otros métodos, marcar como failed si está stuck
        await this.paymentRepo.updatePaymentStatus(payment.id, 'failed');
        
        await this.logPaymentStep(payment.id, 'recovery_failed', 'completed', {
          reason: 'stuck_payment_timeout'
        });
      }
    } catch (error: any) {
      await this.logPaymentStep(payment.id, 'recovery_error', 'failed', {}, error.message);
      console.error(`Error recovering payment ${payment.id}:`, error);
    }
  }

  // Verificar integridad de pagos
  async verifyPaymentIntegrity(paymentId: number): Promise<{
    isConsistent: boolean;
    issues: string[];
    recommendations: string[];
  }> {
    const payment = await this.paymentRepo.getPaymentById(paymentId);
    const issues: string[] = [];
    const recommendations: string[] = [];

    if (!payment) {
      return {
        isConsistent: false,
        issues: ['Payment not found'],
        recommendations: ['Verify payment ID']
      };
    }

    // Verificar consistencia con Mercado Pago
    if (payment.paymentMethod === 'mercadopago') {
      if (payment.paymentId) {
        try {
          const mpPayment = await this.mercadoPagoService.getPayment(payment.paymentId);
          const mpStatus = this.mercadoPagoService.mapMercadoPagoStatus(mpPayment.status);
          
          if (mpStatus !== payment.status) {
            issues.push(`Status mismatch: DB=${payment.status}, MP=${mpStatus}`);
            recommendations.push('Sync status with Mercado Pago');
          }

          if (Math.abs(mpPayment.transaction_amount - payment.amount) > 0.01) {
            issues.push(`Amount mismatch: DB=${payment.amount}, MP=${mpPayment.transaction_amount}`);
            recommendations.push('Verify payment amount');
          }
        } catch (error) {
          issues.push('Cannot verify with Mercado Pago');
          recommendations.push('Check Mercado Pago connectivity');
        }
      } else if (payment.status === 'paid') {
        issues.push('Paid status without Mercado Pago payment ID');
        recommendations.push('Investigate payment source');
      }
    }

    // Verificar clase de conducción
    try {
      const drivingClass = await prisma.drivingClass.findUnique({
        where: { id: payment.drivingClassId }
      });

      if (!drivingClass) {
        issues.push('Associated driving class not found');
        recommendations.push('Verify driving class exists');
      }
    } catch (error) {
      issues.push('Cannot verify driving class');
    }

    return {
      isConsistent: issues.length === 0,
      issues,
      recommendations
    };
  }

  // Obtener historial de recuperación
  async getRecoveryHistory(paymentId: number): Promise<PaymentRecoveryLog[]> {
    const logs = await prisma.$queryRaw<any[]>`
      SELECT * FROM payment_recovery_logs 
      WHERE payment_id = ${paymentId}
      ORDER BY timestamp DESC
    `;

    return logs.map(log => ({
      id: log.id,
      paymentId: log.payment_id,
      step: log.step,
      status: log.status,
      data: JSON.parse(log.data || '{}'),
      error: log.error,
      timestamp: log.timestamp
    }));
  }
}