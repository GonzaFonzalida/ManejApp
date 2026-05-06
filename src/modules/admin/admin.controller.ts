import { Request, Response } from 'express';
import {
  InstructorDocumentReviewStatus,
  Prisma,
} from '@prisma/client';
import { prisma } from '@config/prismaClient';
import { ResponseFormatter } from '../../shared/utils/responseFormatter';
import {
  MANDATORY_DOCUMENT_TYPES,
  evaluateInstructorPublishable,
  instructorMeetsPublicListingRequirements,
  type InstructorForPublishability,
} from '../instructors/instructorPublishable';
import { syncInstructorAutoValidity } from '../instructors/instructorValiditySync';
import { buildInstructorOnboardingPayload } from '../instructors/instructorOnboardingDto';
import ReportService from '../../shared/services/ReportService';
import EmailService from '../../shared/services/EmailService';
import { BookingStatus } from '@shared/utils/bookingStatus';
import diContainer from '@shared/DiContainer/container';
import { NotificationService } from '@notifications/service';

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
        prisma.drivingClass.count({ where: { status: BookingStatus.CONFIRMED } }),
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
            status: BookingStatus.CONFIRMED,
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

  // ==========================================
  // INSTRUCTORS MANAGEMENT
  // ==========================================
  async getInstructors(req: Request, res: Response) {
    try {
      const { status, documentReview } = req.query;
      let where: Prisma.InstructorWhereInput = {};

      if (status === 'pending') {
        where = { isValid: false };
      } else if (status === 'active') {
        where = { isValid: true, isListed: true };
      }

      /** Cola admin: instructores con al menos un doc obligatorio en PENDING_REVIEW (fila review). */
      if (documentReview === 'pending') {
        where = {
          ...where,
          documentReviews: {
            some: { status: InstructorDocumentReviewStatus.PENDING_REVIEW },
          },
        };
      }

      const rows = await prisma.instructor.findMany({
        where,
        include: {
          user: {
            select: {
              name: true,
              surname: true,
              email: true,
              phoneNumber: true,
              profileImage: true,
              isActive: true,
              createdAt: true,
            },
          },
          documentReviews: {
            select: {
              documentType: true,
              status: true,
              rejectionReason: true,
              updatedAt: true,
            },
          },
          _count: {
            select: { drivingClasses: true, cars: true },
          },
        },
        orderBy: { user: { createdAt: 'desc' } },
      });

      const docPendingWithFile = (inst: (typeof rows)[number]) => {
        for (const r of inst.documentReviews) {
          if (r.status !== InstructorDocumentReviewStatus.PENDING_REVIEW) continue;
          if (!MANDATORY_DOCUMENT_TYPES.includes(r.documentType as (typeof MANDATORY_DOCUMENT_TYPES)[number])) {
            continue;
          }
          const key = r.documentType as keyof typeof inst;
          const path = inst[key];
          if (typeof path === 'string' && path.trim().length > 0) return true;
        }
        return false;
      };

      const filtered =
        documentReview === 'pending' ? rows.filter(docPendingWithFile) : rows;

      const payload = filtered.map((inst) => {
        const reviews = inst.documentReviews;
        const pendingCount = reviews.filter(
          (r) => r.status === InstructorDocumentReviewStatus.PENDING_REVIEW
        ).length;
        const rejectedCount = reviews.filter(
          (r) => r.status === InstructorDocumentReviewStatus.REJECTED
        ).length;
        const hasPendingDocumentReview = pendingCount > 0;
        return {
          ...inst,
          documentReviewSummary: {
            pendingCount,
            rejectedCount,
            hasPendingDocumentReview,
          },
        };
      });

      ResponseFormatter.success(res, payload, 'Instructores listados');
    } catch (error) {
      console.error('Error getting instructors:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  async getInstructorDetails(req: Request, res: Response) {
    try {
      const instructorId = parseInt(req.params.id);
      const instructor = await prisma.instructor.findUnique({
        where: { id: instructorId },
        include: {
          user: {
            select: { name: true, surname: true, email: true, phoneNumber: true, profileImage: true, dni: true, isActive: true, createdAt: true }
          },
          cars: true,
          permissions: { include: { permission: true } },
          documentReviews: true,
        }
      });

      if (!instructor) return ResponseFormatter.error(res, 'Instructor no encontrado', 404);

      const instForPub = instructor as unknown as InstructorForPublishability;
      const { publishable, reasons } = evaluateInstructorPublishable(instForPub, instructor.user);
      const { ok: canActivatePublicListing } = instructorMeetsPublicListingRequirements(
        instForPub,
        instructor.user
      );

      const onboarding = buildInstructorOnboardingPayload(instForPub, instructor.user);

      ResponseFormatter.success(
        res,
        {
          ...instructor,
          publishable,
          publishBlockedReasons: reasons,
          canActivatePublicListing,
          onboarding,
        },
        'Detalles del instructor'
      );
    } catch (error) {
      console.error('Error getting instructor details:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  async updateInstructorStatus(req: Request, res: Response) {
    try {
      const instructorId = parseInt(req.params.id);
      const { isValid, isListed, commissionRate, hourlyRate } = req.body;

      const instructor = await prisma.instructor.findUnique({
        where: { id: instructorId },
        include: {
          user: { select: { profileImage: true } },
          documentReviews: { select: { documentType: true, status: true } },
        },
      });
      if (!instructor) return ResponseFormatter.error(res, 'Instructor no encontrado', 404);

      const data: Prisma.InstructorUpdateInput = {};
      if (commissionRate !== undefined) data.commissionRate = Number(commissionRate);
      if (hourlyRate !== undefined) data.hourlyRate = Number(hourlyRate);

      if (isValid === false) {
        data.isValid = false;
        data.validitySuspendedByAdmin = true;
        data.isListed = false;
      } else if (isValid === true) {
        data.isValid = true;
        data.validitySuspendedByAdmin = false;
      } else if (isValid !== undefined) {
        data.isValid = Boolean(isValid);
      }

      if (isListed !== undefined) {
        if (isListed === true) {
          const merged = {
            ...instructor,
            ...data,
            isListed: true,
          } as unknown as InstructorForPublishability;
          const { ok, reasons } = instructorMeetsPublicListingRequirements(merged, instructor.user);
          if (!ok) {
            return ResponseFormatter.error(
              res,
              'No cumple requisitos para aparecer en búsquedas públicas',
              422,
              { reasons }
            );
          }
          data.isListed = true;
        } else {
          data.isListed = false;
        }
      }

      const updated = await prisma.instructor.update({
        where: { id: instructorId },
        data,
      });

      ResponseFormatter.success(res, updated, 'Estado del instructor actualizado');
    } catch (error) {
      console.error('Error updating instructor:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  /**
   * PATCH /admin/instructors/:id/documents/:documentType
   * Body: { status: 'APPROVED' | 'REJECTED', rejectionReason?: string }
   */
  async patchInstructorDocument(req: Request, res: Response) {
    try {
      const instructorId = parseInt(req.params.id, 10);
      const documentType = req.params.documentType as string;
      const allowed = ['dobleComandoImg', 'seguroImg', 'vtvImg', 'reincidenciaImg', 'licenciaImg'];
      if (!Number.isInteger(instructorId) || instructorId < 1) {
        return ResponseFormatter.error(res, 'ID inválido', 422);
      }
      if (!allowed.includes(documentType)) {
        return ResponseFormatter.error(res, 'Tipo de documento inválido', 422);
      }

      const { status, rejectionReason } = req.body as { status?: string; rejectionReason?: string | null };
      if (status !== 'APPROVED' && status !== 'REJECTED') {
        return ResponseFormatter.error(res, 'status debe ser APPROVED o REJECTED', 422);
      }

      const instructor = await prisma.instructor.findUnique({ where: { id: instructorId } });
      if (!instructor) return ResponseFormatter.error(res, 'Instructor no encontrado', 404);

      const nextStatus =
        status === 'APPROVED'
          ? InstructorDocumentReviewStatus.APPROVED
          : InstructorDocumentReviewStatus.REJECTED;

      await prisma.instructorDocumentReview.upsert({
        where: {
          instructorId_documentType: { instructorId, documentType },
        },
        create: {
          instructorId,
          documentType,
          status: nextStatus,
          rejectionReason: status === 'REJECTED' ? (rejectionReason ?? null) : null,
        },
        update: {
          status: nextStatus,
          rejectionReason: status === 'REJECTED' ? (rejectionReason ?? null) : null,
        },
      });

      if (status === 'REJECTED') {
        await prisma.instructor.update({
          where: { id: instructorId },
          data: { isListed: false },
        });
      }

      try {
        const notificationService = diContainer.resolve<NotificationService>('notificationService');
        const instrRow = await prisma.instructor.findUnique({
          where: { id: instructorId },
          select: { userId: true },
        });
        if (instrRow) {
          if (status === 'APPROVED') {
            void notificationService.sendPushToUser(
              instrRow.userId,
              'Documento verificado',
              'Ya revisamos un archivo. Entrá al centro de alta por si queda algo pendiente.',
              { type: 'instructor_doc', documentType, role: 'INSTRUCTOR' },
            );
          } else {
            void notificationService.sendPushToUser(
              instrRow.userId,
              'Documento a corregir',
              'Hay un archivo que necesitás volver a subir. Abrí el centro de alta para ver el detalle.',
              { type: 'instructor_doc', documentType, role: 'INSTRUCTOR' },
            );
          }
        }
      } catch (pushErr) {
        console.error('Push instructor document:', pushErr);
      }

      await syncInstructorAutoValidity(instructorId);

      ResponseFormatter.success(
        res,
        { instructorId, documentType, status: nextStatus },
        'Estado del documento actualizado'
      );
    } catch (error) {
      console.error('Error patchInstructorDocument:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  // ==========================================
  // STUDENTS MANAGEMENT
  // ==========================================
  async getStudents(req: Request, res: Response) {
    try {
      const students = await prisma.student.findMany({
        include: {
          user: {
            select: { name: true, surname: true, email: true, phoneNumber: true, isActive: true, createdAt: true, lastLoginAt: true }
          },
          _count: {
            select: { drivingClasses: true }
          }
        },
        orderBy: { user: { createdAt: 'desc' } }
      });
      ResponseFormatter.success(res, students, 'Estudiantes listados');
    } catch (error) {
      console.error('Error getting students:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  // ==========================================
  // CLASSES & PAYMENTS MANAGEMENT
  // ==========================================
  async getClasses(req: Request, res: Response) {
    try {
      const classes = await prisma.drivingClass.findMany({
        include: {
          instructor: { select: { user: { select: { name: true, surname: true } } } },
          student: { select: { user: { select: { name: true, surname: true } } } },
          payments: true
        },
        orderBy: { date: 'desc' },
        take: 100 // Limit for MVP
      });
      ResponseFormatter.success(res, classes, 'Clases listadas');
    } catch (error) {
      console.error('Error getting classes:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  async getPayments(req: Request, res: Response) {
    try {
      const payments = await prisma.payment.findMany({
        include: {
          drivingClass: {
            select: {
              instructor: { select: { user: { select: { name: true, surname: true } } } },
              student: { select: { user: { select: { name: true, surname: true } } } }
            }
          }
        },
        orderBy: { createdAt: 'desc' },
        take: 100
      });
      ResponseFormatter.success(res, payments, 'Pagos listados');
    } catch (error) {
      console.error('Error getting payments:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  /** Conciliación mínima: totales pagados vs comisiones y anomalías (solo ADMIN vía ruta). */
  async getPaymentsReconciliation(req: Request, res: Response) {
    try {
      const from = req.query.from ? new Date(String(req.query.from)) : undefined;
      const to = req.query.to ? new Date(String(req.query.to)) : undefined;

      const dateFilter: Prisma.DateTimeFilter | undefined =
        from || to
          ? {
              ...(from ? { gte: from } : {}),
              ...(to ? { lte: to } : {}),
            }
          : undefined;

      const baseWhere: Prisma.PaymentWhereInput = {
        status: 'paid',
        ...(dateFilter ? { updatedAt: dateFilter } : {}),
      };

      const [aggregate, paidMissingCommission, sampleWithMp] = await Promise.all([
        prisma.payment.aggregate({
          where: baseWhere,
          _count: { _all: true },
          _sum: {
            amount: true,
            appCommission: true,
            instructorAmount: true,
            mpTransactionAmount: true,
          },
        }),
        prisma.payment.count({
          where: {
            ...baseWhere,
            OR: [
              { appCommission: null },
              { instructorAmount: null },
              { commissionRate: null },
            ],
          },
        }),
        prisma.payment.findMany({
          where: { ...baseWhere, mpTransactionAmount: { not: null } },
          take: 500,
          select: { id: true, amount: true, mpTransactionAmount: true, drivingClassId: true },
        }),
      ]);

      const mpAmountMismatches = sampleWithMp.filter(
        (p) =>
          p.mpTransactionAmount != null &&
          Math.abs(p.amount - p.mpTransactionAmount) > 0.02
      ).length;

      ResponseFormatter.success(
        res,
        {
          period: { from: from?.toISOString() ?? null, to: to?.toISOString() ?? null },
          paidCount: aggregate._count._all,
          sums: {
            grossRegistered: aggregate._sum.amount ?? 0,
            appCommission: aggregate._sum.appCommission ?? 0,
            instructorNet: aggregate._sum.instructorAmount ?? 0,
            mpTransactionAmountCaptured: aggregate._sum.mpTransactionAmount ?? 0,
          },
          anomalies: {
            paidMissingCommissionFields: paidMissingCommission,
            sampledMpAmountMismatches: mpAmountMismatches,
            sampledWithMpAmount: sampleWithMp.length,
          },
        },
        'Conciliación de pagos'
      );
    } catch (error) {
      console.error('Error getting payments reconciliation:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  // ==========================================
  // MESSAGES MONITORING (MVP)
  // ==========================================
  async getConversations(req: Request, res: Response) {
    try {
      const conversations = await prisma.conversation.findMany({
        include: {
          participant1: { select: { id: true, name: true, surname: true, role: true } },
          participant2: { select: { id: true, name: true, surname: true, role: true } },
          messages: {
            orderBy: { sentAt: 'desc' },
            take: 1
          }
        },
        orderBy: { updatedAt: 'desc' },
        take: 50
      });
      ResponseFormatter.success(res, conversations, 'Conversaciones listadas');
    } catch (error) {
      console.error('Error getting conversations:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }

  async getConversationMessages(req: Request, res: Response) {
    try {
      const conversationId = parseInt(req.params.id);
      const messages = await prisma.message.findMany({
        where: { conversationId },
        include: {
          sender: { select: { id: true, name: true, role: true } }
        },
        orderBy: { sentAt: 'asc' }
      });
      ResponseFormatter.success(res, messages, 'Mensajes listados');
    } catch (error) {
      console.error('Error getting messages:', error);
      ResponseFormatter.error(res, 'Error interno del servidor', 500);
    }
  }
}
