import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { ResponseFormatter } from '../../shared/utils/responseFormatter';
import ReportService from '../../shared/services/ReportService';
import EmailService from '../../shared/services/EmailService';

const prisma = new PrismaClient();

export class AdminController {
  async getDashboardStats(req: Request, res: Response) {
    try {
      const [
        totalUsers,
        totalInstructors,
        totalStudents,
        totalClasses,
        totalPayments,
        activeClasses,
        pendingPayments,
        totalRevenue,
        appCommissions
      ] = await Promise.all([
        prisma.user.count(),
        prisma.instructor.count(),
        prisma.student.count(),
        prisma.drivingClass.count(),
        prisma.payment.count(),
        prisma.drivingClass.count({ where: { status: 'scheduled' } }),
        prisma.payment.count({ where: { status: 'pending' } }),
        prisma.payment.aggregate({
          where: { status: 'approved' },
          _sum: { amount: true }
        }),
        prisma.payment.aggregate({
          where: { 
            status: 'approved',
            appCommission: { not: null }
          },
          _sum: { appCommission: true }
        })
      ]);

      const stats = {
        users: {
          total: totalUsers,
          instructors: totalInstructors,
          students: totalStudents
        },
        classes: {
          total: totalClasses,
          active: activeClasses
        },
        payments: {
          total: totalPayments,
          pending: pendingPayments,
          totalRevenue: totalRevenue._sum.amount || 0,
          appCommissions: appCommissions._sum.appCommission || 0
        }
      };

      ResponseFormatter.success(res, stats, 'Estadísticas del dashboard');
    } catch (error) {
      console.error('Error getting dashboard stats:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  async getSystemHealth(req: Request, res: Response) {
    try {
      const [
        inactiveUsers,
        failedPayments,
        instructorsWithoutMP,
        oldPendingClasses
      ] = await Promise.all([
        prisma.user.count({ where: { isActive: false } }),
        prisma.payment.count({ where: { status: 'failed' } }),
        prisma.instructor.count({ where: { mpCollectorId: null } }),
        prisma.drivingClass.count({
          where: {
            status: 'scheduled',
            date: { lt: new Date(Date.now() - 24 * 60 * 60 * 1000) }
          }
        })
      ]);

      const health = {
        issues: {
          inactiveUsers,
          failedPayments,
          instructorsWithoutMP,
          oldPendingClasses
        },
        status: (inactiveUsers + failedPayments + instructorsWithoutMP + oldPendingClasses) === 0 ? 'healthy' : 'needs_attention'
      };

      ResponseFormatter.success(res, health, 'Estado del sistema');
    } catch (error) {
      console.error('Error getting system health:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  async manageUser(req: Request, res: Response) {
    try {
      const { userId } = req.params;
      const { action } = req.body;

      const user = await prisma.user.findUnique({
        where: { id: parseInt(userId) }
      });

      if (!user) {
        return ResponseFormatter.error(res, 'Usuario no encontrado', 404);
      }

      switch (action) {
        case 'activate':
          await prisma.user.update({
            where: { id: parseInt(userId) },
            data: { isActive: true }
          });
          break;
        case 'deactivate':
          await prisma.user.update({
            where: { id: parseInt(userId) },
            data: { isActive: false }
          });
          break;
        default:
          return ResponseFormatter.error(res, 'Acción no válida', 400);
      }

      ResponseFormatter.success(res, null, `Usuario ${action} exitosamente`);
    } catch (error) {
      console.error('Error managing user:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  async getReportConfig(req: Request, res: Response) {
    try {
      const config = await (prisma as any).systemConfig.findFirst();
      if (!config) {
        // Crear configuración por defecto
        const defaultConfig = await (prisma as any).systemConfig.create({
          data: {
            reportInterval: 'weekly',
            reportEmails: JSON.stringify(['admin@manejapp.com']),
            errorAlertsEnabled: true,
          }
        });
        return ResponseFormatter.success(res, defaultConfig, 'Configuración por defecto creada');
      }

      const parsedConfig = {
        ...config,
        reportEmails: JSON.parse(config.reportEmails || '[]'),
      };

      ResponseFormatter.success(res, parsedConfig, 'Configuración obtenida');
    } catch (error) {
      console.error('Error getting report config:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  async updateReportConfig(req: Request, res: Response) {
    try {
      const { reportInterval, reportEmails, errorAlertsEnabled } = req.body;

      // Validar intervalo
      const validIntervals = ['daily', 'weekly', 'monthly'];
      if (reportInterval && !validIntervals.includes(reportInterval)) {
        return ResponseFormatter.error(res, 'Intervalo inválido. Use: daily, weekly, monthly', 400);
      }

      // Validar emails
      if (reportEmails && !Array.isArray(reportEmails)) {
        return ResponseFormatter.error(res, 'reportEmails debe ser un array', 400);
      }

      const config = await (prisma as any).systemConfig.findFirst();
      if (!config) {
        return ResponseFormatter.error(res, 'Configuración no encontrada', 404);
      }

      const updatedConfig = await (prisma as any).systemConfig.update({
        where: { id: config.id },
        data: {
          ...(reportInterval && { reportInterval }),
          ...(reportEmails && { reportEmails: JSON.stringify(reportEmails) }),
          ...(errorAlertsEnabled !== undefined && { errorAlertsEnabled }),
        }
      });

      const parsedConfig = {
        ...updatedConfig,
        reportEmails: JSON.parse(updatedConfig.reportEmails || '[]'),
      };

      ResponseFormatter.success(res, parsedConfig, 'Configuración actualizada');
    } catch (error) {
      console.error('Error updating report config:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  async sendReportNow(req: Request, res: Response) {
    try {
      const reportService = new ReportService();
      const emailService = new EmailService();

      const statistics = await reportService.generateStatistics();
      const config = await (prisma as any).systemConfig.findFirst();

      if (!config) {
        return ResponseFormatter.error(res, 'Configuración de reportes no encontrada', 404);
      }

      const recipients = JSON.parse(config.reportEmails || '[]');
      if (recipients.length === 0) {
        return ResponseFormatter.error(res, 'No hay emails configurados para reportes', 400);
      }

      await emailService.sendSystemReport(recipients, statistics);

      // Actualizar última fecha de envío
      await (prisma as any).systemConfig.update({
        where: { id: config.id },
        data: { lastReportSent: new Date() }
      });

      ResponseFormatter.success(res, null, `Reporte enviado a ${recipients.length} administradores`);
    } catch (error) {
      console.error('Error sending report:', error);
      ResponseFormatter.error(res, 'Error enviando reporte', 500);
    }
  }
}