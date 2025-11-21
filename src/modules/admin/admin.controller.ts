import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { ResponseFormatter } from '../../shared/utils/responseFormatter';

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
}