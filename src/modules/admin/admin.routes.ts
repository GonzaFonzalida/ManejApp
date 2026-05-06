import { Router } from 'express';
import { AdminController } from './admin.controller';
import { authenticateToken, requireRole } from '../../shared/middlewares/auth';

const router = Router();
const controller = new AdminController();

router.use(authenticateToken);
router.use(requireRole(['ADMIN']));

router.get('/dashboard/stats', controller.getDashboardStats);
router.get('/system/health', controller.getSystemHealth);
router.patch('/users/:userId/manage', controller.manageUser);

// Report configuration
router.get('/reports/config', controller.getReportConfig);
router.put('/reports/config', controller.updateReportConfig);
router.post('/reports/send-now', controller.sendReportNow);

// Instructors
router.get('/instructors', controller.getInstructors);
router.get('/instructors/:id', controller.getInstructorDetails);
router.patch('/instructors/:id/status', controller.updateInstructorStatus);
router.patch('/instructors/:id/documents/:documentType', controller.patchInstructorDocument);

// Students
router.get('/students', controller.getStudents);

// Classes & Payments
router.get('/classes', controller.getClasses);
router.get('/payments', controller.getPayments);
router.get('/payments/reconciliation', controller.getPaymentsReconciliation);

// Messages
router.get('/conversations', controller.getConversations);
router.get('/conversations/:id/messages', controller.getConversationMessages);

export default router;