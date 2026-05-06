import { PaymentRepository } from './repositories/PaymentRepository';
import { Payment, CreatePaymentData } from './payment.types';
import CommissionPaymentService from './commission-payment.service';
import CustomizedError from '@shared/classes/CustomizedError';
import { AuditService, AuditAction } from '@shared/services/AuditService';
import { prisma } from '@config/prismaClient';
import { InstructorPayoutStatus } from './payment-commission.policy';

export default class CommissionEnhancedService {
  constructor(
    private paymentRepo: PaymentRepository,
    private commissionService: CommissionPaymentService
  ) { }

  async createPaymentWithCommission(data: CreatePaymentData, userId?: number): Promise<Payment> {
    return await prisma.$transaction(async (tx) => {
      // Get driving class and instructor info
      const drivingClass = await tx.drivingClass.findUnique({
        where: { id: data.drivingClassId },
        include: {
          instructor: {
            include: { user: true }
          }
        }
      });

      if (!drivingClass) {
        throw new CustomizedError('Clase de conducción no encontrada', 404);
      }

      const instructor = drivingClass.instructor;

      // Calculate commission based on the instructor's specific rate in the DB (default 20%)
      const { appCommission, instructorAmount } = this.commissionService.calculateCommission(data.amount, instructor.commissionRate);

      // Create payment with commission data
      const paymentData = {
        ...data,
        appCommission,
        instructorAmount,
        commissionRate: instructor.commissionRate
      };

      const payment = await this.paymentRepo.createPayment({
        ...paymentData,
        instructorPayoutStatus: InstructorPayoutStatus.NOT_APPLICABLE,
      });

      // If Mercado Pago payment, create preference with commission
      if (data.paymentMethod === 'mercadopago') {
        if (!instructor.mpCollectorId) {
          throw new CustomizedError('Instructor no tiene cuenta de Mercado Pago configurada', 400);
        }

        try {
          const preference = await this.commissionService.createPreferenceWithCommission({
            amount: data.amount,
            description: `Clase de conducción #${data.drivingClassId}`,
            externalReference: payment.id.toString(),
            instructorCollectorId: instructor.mpCollectorId,
            overrideCommissionRate: instructor.commissionRate
          });

          // Update payment with MP data
          await this.paymentRepo.updatePaymentWithMercadoPagoData(payment.id, {
            preferenceId: preference.id,
            externalReference: payment.id.toString(),
          });

          // Audit log
          AuditService.logUserAction(
            userId || instructor.userId,
            AuditAction.CREATE,
            'commission_payment',
            payment.id,
            {
              amount: data.amount,
              appCommission,
              instructorAmount,
              commissionRate: paymentData.commissionRate
            }
          );

          return await this.paymentRepo.getPaymentById(payment.id) as Payment;
        } catch (error) {
          throw new CustomizedError('Error al crear preferencia con comisión', 500);
        }
      }

      return payment;
    });
  }

  async getCommissionReport(startDate?: Date, endDate?: Date): Promise<{
    totalPayments: number;
    totalAmount: number;
    totalAppCommission: number;
    totalInstructorAmount: number;
    averageCommissionRate: number;
  }> {
    const whereClause: any = {
      status: 'paid',
      appCommission: { not: null }
    };

    if (startDate) whereClause.createdAt = { gte: startDate };
    if (endDate) whereClause.createdAt = { ...whereClause.createdAt, lte: endDate };

    const payments = await prisma.payment.findMany({
      where: whereClause,
      select: {
        amount: true,
        appCommission: true,
        instructorAmount: true,
        commissionRate: true
      }
    });

    const totalPayments = payments.length;
    const totalAmount = payments.reduce((sum, p) => sum + p.amount, 0);
    const totalAppCommission = payments.reduce((sum, p) => sum + (p.appCommission || 0), 0);
    const totalInstructorAmount = payments.reduce((sum, p) => sum + (p.instructorAmount || 0), 0);
    const averageCommissionRate = totalPayments > 0
      ? payments.reduce((sum, p) => sum + (p.commissionRate || 0), 0) / totalPayments
      : 0;

    return {
      totalPayments,
      totalAmount,
      totalAppCommission,
      totalInstructorAmount,
      averageCommissionRate
    };
  }

  async getInstructorEarnings(instructorId: number, startDate?: Date, endDate?: Date): Promise<{
    totalEarnings: number;
    totalClasses: number;
    averagePerClass: number;
    commissionRate: number;
  }> {
    const whereClause: any = {
      status: 'paid',
      drivingClass: { instructorId },
      instructorAmount: { not: null }
    };

    if (startDate) whereClause.createdAt = { gte: startDate };
    if (endDate) whereClause.createdAt = { ...whereClause.createdAt, lte: endDate };

    const payments = await prisma.payment.findMany({
      where: whereClause,
      select: {
        instructorAmount: true,
        commissionRate: true
      }
    });

    const totalEarnings = payments.reduce((sum, p) => sum + (p.instructorAmount || 0), 0);
    const totalClasses = payments.length;
    const averagePerClass = totalClasses > 0 ? totalEarnings / totalClasses : 0;
    const commissionRate = payments.length > 0 ? (payments[0].commissionRate || 20) : 20;

    return {
      totalEarnings,
      totalClasses,
      averagePerClass,
      commissionRate
    };
  }
}