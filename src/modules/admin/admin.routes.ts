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

export default router;