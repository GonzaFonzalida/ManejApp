import { prisma } from "@config/prismaClient";

export interface AppStatistics {
  users: {
    total: number;
    active: number;
    students: number;
    instructors: number;
    admins: number;
    unverified: number;
  };
  instructors: {
    total: number;
    valid: number;
    invalid: number;
    withCars: number;
    withoutCars: number;
  };
  classes: {
    total: number;
    scheduled: number;
    completed: number;
    cancelled: number;
    today: number;
  };
  payments: {
    total: number;
    pending: number;
    completed: number;
    failed: number;
    totalAmount: number;
    recovered: number;
  };
  system: {
    uptime: string;
    lastBackup?: string;
    errorCount: number;
    recentErrors: any[];
  };
}

export default class ReportService {
  private startTime: Date;

  constructor() {
    this.startTime = new Date();
  }

  async generateStatistics(): Promise<AppStatistics> {
    const [
      userStats,
      instructorStats,
      classStats,
      paymentStats,
      systemStats,
    ] = await Promise.all([
      this.getUserStatistics(),
      this.getInstructorStatistics(),
      this.getClassStatistics(),
      this.getPaymentStatistics(),
      this.getSystemStatistics(),
    ]);

    return {
      users: userStats,
      instructors: instructorStats,
      classes: classStats,
      payments: paymentStats,
      system: systemStats,
    };
  }

  private async getUserStatistics() {
    const [
      total,
      active,
      students,
      instructors,
      admins,
      unverified,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { isActive: true } }),
      prisma.user.count({ where: { role: 'STUDENT' } }),
      prisma.user.count({ where: { role: 'INSTRUCTOR' } }),
      prisma.user.count({ where: { role: 'ADMIN' } }),
      prisma.user.count({ where: { emailVerifiedAt: null } }),
    ]);

    return {
      total,
      active,
      students,
      instructors,
      admins,
      unverified,
    };
  }

  private async getInstructorStatistics() {
    const [
      total,
      valid,
      invalid,
      withCars,
      withoutCars,
    ] = await Promise.all([
      prisma.instructor.count(),
      prisma.instructor.count({ where: { isValid: true } }),
      prisma.instructor.count({ where: { isValid: false } }),
      prisma.instructor.count({
        where: {
          cars: {
            some: {}
          }
        }
      }),
      prisma.instructor.count({
        where: {
          cars: {
            none: {}
          }
        }
      }),
    ]);

    return {
      total,
      valid,
      invalid,
      withCars,
      withoutCars,
    };
  }

  private async getClassStatistics() {
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    const [
      total,
      scheduled,
      completed,
      cancelled,
      todayClasses,
    ] = await Promise.all([
      prisma.drivingClass.count(),
      prisma.drivingClass.count({ where: { status: 'scheduled' } }),
      prisma.drivingClass.count({ where: { status: 'completed' } }),
      prisma.drivingClass.count({ where: { status: 'cancelled' } }),
      prisma.drivingClass.count({
        where: {
          date: {
            gte: today,
            lt: new Date(today.getTime() + 24 * 60 * 60 * 1000),
          }
        }
      }),
    ]);

    return {
      total,
      scheduled,
      completed,
      cancelled,
      today: todayClasses,
    };
  }

  private async getPaymentStatistics() {
    const [
      total,
      pending,
      completed,
      failed,
      totalAmountResult,
      recovered,
    ] = await Promise.all([
      prisma.payment.count(),
      prisma.payment.count({ where: { status: 'pending' } }),
      prisma.payment.count({ where: { status: 'completed' } }),
      prisma.payment.count({ where: { status: 'failed' } }),
      prisma.payment.aggregate({
        _sum: { amount: true },
        where: { status: 'completed' }
      }),
      prisma.payment.count({ where: { lastRecoveryAt: { not: null } } }),
    ]);

    return {
      total,
      pending,
      completed,
      failed,
      totalAmount: totalAmountResult._sum.amount || 0,
      recovered,
    };
  }

  private async getSystemStatistics() {
    // Calcular uptime
    const uptime = Date.now() - this.startTime.getTime();
    const uptimeString = this.formatUptime(uptime);

    // Obtener errores recientes (últimas 24 horas)
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const recentErrors = await prisma.$queryRaw<
      Array<{
        id: number;
        timestamp: Date;
        level: string;
        message: string;
        context: any;
        error: any;
        metadata: any;
        created_at: Date;
      }>
    >`
      SELECT id, timestamp, level, message, context, error, metadata, created_at
      FROM logs
      WHERE level = 'error' AND timestamp >= ${yesterday}
      ORDER BY timestamp DESC
      LIMIT 10
    `;

    return {
      uptime: uptimeString,
      errorCount: recentErrors.length,
      recentErrors: recentErrors.map((error: any) => ({
        timestamp: error.timestamp,
        message: error.message,
        context: error.context,
      })),
    };
  }

  private formatUptime(milliseconds: number): string {
    const seconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ${hours % 24}h`;
    if (hours > 0) return `${hours}h ${minutes % 60}m`;
    if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
    return `${seconds}s`;
  }

  async sendErrorAlert(error: Error, context?: any) {
    // Implementar lógica para enviar alertas de error crítico
    // Esto se llamará desde el middleware de errores
    console.error('Error crítico detectado:', error, context);
    // TODO: Implementar envío de email de alerta
  }
}