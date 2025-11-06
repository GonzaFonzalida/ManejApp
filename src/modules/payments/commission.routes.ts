import { Router } from 'express';
import CommissionController from './commission.controller';
import CommissionEnhancedService from './commission-enhanced.service';
import CommissionPaymentService from './commission-payment.service';
import PrismaPaymentRepository from './repositories/PrismaPaymentRepository';
import { authenticate } from '@auth/auth.middlewares';
import { generalRateLimit } from '@shared/middlewares/security';
import { validateZodSchema } from '@shared/middlewares/validation';
import * as schema from './payment.schemas';

const paymentRepo = new PrismaPaymentRepository();
const commissionPaymentService = new CommissionPaymentService();
const commissionService = new CommissionEnhancedService(paymentRepo, commissionPaymentService);
const controller = new CommissionController(commissionService);

const commissionRoutes = Router();

// Apply security middleware
commissionRoutes.use(authenticate);
commissionRoutes.use(generalRateLimit);

// Commission-based payment creation
commissionRoutes.post('/with-commission',
  validateZodSchema(schema.createPaymentSchema),
  controller.createPaymentWithCommission
);

// Commission reports (admin only)
commissionRoutes.get('/commission-report',
  controller.getCommissionReport
);

// Instructor earnings
commissionRoutes.get('/instructor/:instructorId/earnings',
  controller.getInstructorEarnings
);

export default commissionRoutes;