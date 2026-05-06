import cron from 'node-cron';
import { PrismaClient, SlotStatus, BookingStatus } from '@prisma/client';
import ReportService from './ReportService';
import EmailService from './EmailService';
import diContainer from '../DiContainer/container';
import { NotificationService } from '../../modules/notifications/service';

const prisma = new PrismaClient();

function reminderWhenLine(d: Date): string {
  return d.toLocaleString('es-AR', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export class SchedulerService {
  private static instance: SchedulerService;
  private jobs: Map<string, cron.ScheduledTask> = new Map();
  private reportService: ReportService;
  private emailService: EmailService;

  private constructor() {
    this.reportService = new ReportService();
    this.emailService = new EmailService();
  }

  static getInstance(): SchedulerService {
    if (!SchedulerService.instance) {
      SchedulerService.instance = new SchedulerService();
    }
    return SchedulerService.instance;
  }

  start() {
    this.schedulePaymentRecovery();
    this.scheduleHoldExpiryCleanup();
    this.scheduleSystemCleanup();
    this.scheduleSystemReports();
    this.scheduleClassReminders();
    console.log('✅ Scheduler iniciado');
  }

  /** Cada 15 min: push ~1h antes de clase confirmada (una vez por reserva). */
  private scheduleClassReminders() {
    const job = cron.schedule('*/15 * * * *', async () => {
      try {
        const notificationService = diContainer.resolve<NotificationService>('notificationService');
        const now = Date.now();
        const from = new Date(now + 50 * 60 * 1000);
        const to = new Date(now + 70 * 60 * 1000);
        const classes = await prisma.drivingClass.findMany({
          where: {
            status: BookingStatus.CONFIRMED,
            classReminderSentAt: null,
            date: { gte: from, lte: to },
          },
          select: {
            id: true,
            date: true,
            studentId: true,
            instructorId: true,
          },
        });
        for (const c of classes) {
          const when = reminderWhenLine(c.date);
          const stu = await prisma.student.findUnique({
            where: { id: c.studentId },
            select: { userId: true },
          });
          const instr = await prisma.instructor.findUnique({
            where: { id: c.instructorId },
            select: { userId: true },
          });
          if (stu) {
            void notificationService.sendPushToUser(
              stu.userId,
              'Tu clase arranca pronto',
              `En menos de una hora (${when}). Revisá la reserva por si cambió algo.`,
              { type: 'student_booking', bookingId: String(c.id), role: 'STUDENT' },
            );
          }
          if (instr) {
            void notificationService.sendPushToUser(
              instr.userId,
              'Próxima clase',
              `Tenés una clase en camino (${when}).`,
              { type: 'instructor_booking', bookingId: String(c.id), role: 'INSTRUCTOR' },
            );
          }
          await prisma.drivingClass.update({
            where: { id: c.id },
            data: { classReminderSentAt: new Date() },
          });
        }
        if (classes.length > 0) {
          console.log(`⏰ Recordatorios de clase: ${classes.length}`);
        }
      } catch (error) {
        console.error('Error en recordatorios de clase:', error);
      }
    });
    this.jobs.set('classReminders', job);
  }

  /** Cada 2 min: libera slots HELD vencidos y cancela booking PENDING_PAYMENT. Idempotente. */
  private scheduleHoldExpiryCleanup() {
    const holdCleanupJob = cron.schedule('*/2 * * * *', async () => {
      try {
        const now = new Date();
        const expired = await prisma.scheduleSlot.findMany({
          where: { status: SlotStatus.HELD, heldUntil: { lt: now } },
          select: { id: true, drivingClassId: true },
        });
        for (const s of expired) {
          await prisma.$transaction(async (tx) => {
            if (s.drivingClassId) {
              await tx.drivingClass.updateMany({
                where: { id: s.drivingClassId, status: BookingStatus.PENDING_PAYMENT },
                data: { status: BookingStatus.CANCELLED },
              });
              await tx.payment.updateMany({
                where: { drivingClassId: s.drivingClassId, status: 'pending' },
                data: { status: 'cancelled' },
              });
            }
            await tx.scheduleSlot.update({
              where: { id: s.id },
              data: { status: SlotStatus.AVAILABLE, heldUntil: null, drivingClassId: null },
            });
          });
        }
        if (expired.length > 0) {
          console.log(`🕐 Hold expiry: ${expired.length} slot(s) liberados`);
        }
      } catch (error) {
        console.error('Error en hold expiry cleanup:', error);
      }
    });
    this.jobs.set('holdExpiryCleanup', holdCleanupJob);
  }

  private schedulePaymentRecovery() {
    const recoveryJob = cron.schedule('*/30 * * * *', async () => {
      try {
        const stuckPayments = await prisma.payment.findMany({
          where: {
            status: 'pending',
            createdAt: { lt: new Date(Date.now() - 10 * 60 * 1000) },
            recoveryAttempts: { lt: 3 }
          },
          take: 10
        });

        for (const payment of stuckPayments) {
          await prisma.payment.update({
            where: { id: payment.id },
            data: {
              recoveryAttempts: payment.recoveryAttempts + 1,
              lastRecoveryAt: new Date()
            }
          });
        }

        if (stuckPayments.length > 0) {
          console.log(`🔄 ${stuckPayments.length} pagos en recuperación`);
        }
      } catch (error) {
        console.error('Error en recuperación:', error);
      }
    });

    this.jobs.set('paymentRecovery', recoveryJob);
  }

  private scheduleSystemCleanup() {
    const cleanupJob = cron.schedule('0 2 * * *', async () => {
      try {
        const [expiredTokens, oldLogs] = await Promise.all([
          prisma.blacklistedToken.deleteMany({
            where: { expiresAt: { lt: new Date() } }
          }),
          prisma.paymentRecoveryLog.deleteMany({
            where: {
              timestamp: { lt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
            }
          })
        ]);

        console.log(`🧹 Limpieza: ${expiredTokens.count} tokens, ${oldLogs.count} logs`);
      } catch (error) {
        console.error('Error en limpieza:', error);
      }
    });

    this.jobs.set('systemCleanup', cleanupJob);
  }

  private async scheduleSystemReports() {
    try {
      // Obtener configuración de reportes
      const config = await (prisma as any).systemConfig.findFirst();
      if (!config) {
        // Crear configuración por defecto
        await (prisma as any).systemConfig.create({
          data: {
            reportInterval: 'weekly',
            reportEmails: JSON.stringify(['admin@manejapp.com']),
            errorAlertsEnabled: true,
          }
        });
        console.log('📊 Configuración de reportes creada por defecto');
        return;
      }

      // Programar envío de reportes según intervalo
      let cronExpression: string;
      switch (config.reportInterval) {
        case 'daily':
          cronExpression = '0 9 * * *'; // Todos los días a las 9 AM
          break;
        case 'weekly':
          cronExpression = '0 9 * * 1'; // Todos los lunes a las 9 AM
          break;
        case 'monthly':
          cronExpression = '0 9 1 * *'; // Primer día del mes a las 9 AM
          break;
        default:
          cronExpression = '0 9 * * 1'; // Por defecto semanal
      }

      const reportJob = cron.schedule(cronExpression, async () => {
        try {
          console.log('📊 Generando reporte del sistema...');

          const statistics = await this.reportService.generateStatistics();
          const recipients = JSON.parse(config.reportEmails || '[]');

          if (recipients.length > 0) {
            await this.emailService.sendSystemReport(recipients, statistics);

            // Actualizar última fecha de envío
            await (prisma as any).systemConfig.update({
              where: { id: config.id },
              data: { lastReportSent: new Date() }
            });

            console.log(`📧 Reporte enviado a ${recipients.length} administradores`);
          }
        } catch (error) {
          console.error('Error enviando reporte:', error);
        }
      });

      this.jobs.set('systemReports', reportJob);
      console.log(`📅 Reportes programados: ${config.reportInterval} (${cronExpression})`);

    } catch (error) {
      console.error('Error configurando reportes:', error);
    }
  }

  stop() {
    this.jobs.forEach((job) => job.stop());
    this.jobs.clear();
  }
}

export default SchedulerService.getInstance();