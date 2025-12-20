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

export default router;