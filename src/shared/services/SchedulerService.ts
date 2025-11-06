import cron from 'node-cron';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class SchedulerService {
  private static instance: SchedulerService;
  private jobs: Map<string, cron.ScheduledTask> = new Map();

  private constructor() {}

  static getInstance(): SchedulerService {
    if (!SchedulerService.instance) {
      SchedulerService.instance = new SchedulerService();
    }
    return SchedulerService.instance;
  }

  start() {
    this.schedulePaymentRecovery();
    this.scheduleSystemCleanup();
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

  stop() {
    this.jobs.forEach((job) => job.stop());
    this.jobs.clear();
  }
}

export default SchedulerService.getInstance();