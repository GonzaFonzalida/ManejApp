import { Router } from 'express';
import ImprovedCarController from './improved-cars.controller';
import ImprovedCarService from './improved-cars.service';
import { PrismaCarRepository } from './repositories/PrismaCarRepository';
import { validateZodSchema } from '@shared/middlewares/validation';
import { authenticate } from '@auth/auth.middlewares';
import { generalRateLimit } from '@shared/middlewares/security';
import {
  createCarSchema,
  updateCarSchema,
  carFiltersSchema,
  carIdSchema
} from './improved-cars.schemas';

const repo = new PrismaCarRepository();
const service = new ImprovedCarService(repo);
const controller = new ImprovedCarController(service);

const improvedCarRoutes = Router();

// Apply security middleware
improvedCarRoutes.use(authenticate);
improvedCarRoutes.use(generalRateLimit);

// CRUD operations
improvedCarRoutes.post('/',
  validateZodSchema(createCarSchema),
  controller.createCar
);

improvedCarRoutes.get('/',
  validateZodSchema(carFiltersSchema),
  controller.listCars
);

improvedCarRoutes.get('/instructor/:instructorId',
  controller.getCarsByInstructor
);

improvedCarRoutes.get('/:id',
  validateZodSchema(carIdSchema),
  controller.getCarById
);

improvedCarRoutes.put('/:id',
  validateZodSchema(carIdSchema),
  validateZodSchema(updateCarSchema),
  controller.updateCar
);

improvedCarRoutes.patch('/:id/toggle-status',
  validateZodSchema(carIdSchema),
  controller.toggleCarStatus
);

improvedCarRoutes.delete('/:id',
  validateZodSchema(carIdSchema),
  controller.deleteCar
);

export default improvedCarRoutes;