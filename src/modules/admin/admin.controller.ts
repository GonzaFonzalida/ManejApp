import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { formatResponse } from '../../shared/utils/responseFormatter';

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

      res.json(formatResponse(true, 'Estadísticas del dashboard', stats));
    } catch (error) {
      console.error('Error getting dashboard stats:', error);
      res.status(500).json(formatResponse(false, 'Error interno del servidor'));
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

      res.json(formatResponse(true, 'Estado del sistema', health));
    } catch (error) {
      console.error('Error getting system health:', error);
      res.status(500).json(formatResponse(false, 'Error interno del servidor'));
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
        return res.status(404).json(formatResponse(false, 'Usuario no encontrado'));
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
          return res.status(400).json(formatResponse(false, 'Acción no válida'));
      }

      res.json(formatResponse(true, `Usuario ${action} exitosamente`));
    } catch (error) {
      console.error('Error managing user:', error);
      res.status(500).json(formatResponse(false, 'Error interno del servidor'));
    }
  }
}