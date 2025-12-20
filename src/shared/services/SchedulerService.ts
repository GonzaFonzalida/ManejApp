import cron from 'node-cron';
import { PrismaClient } from '@prisma/client';
import ReportService from './ReportService';
import EmailService from './EmailService';

const prisma = new PrismaClient();

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
    this.scheduleSystemCleanup();
    this.scheduleSystemReports();
    console.log('✅ Scheduler iniciado');
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