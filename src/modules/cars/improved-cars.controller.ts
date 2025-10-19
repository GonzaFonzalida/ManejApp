import { Request, Response } from 'express';
import ImprovedCarService from './improved-cars.service';
import { ExpressFunction } from '@sharedTypes/ExpressFunction';
import { ResponseFormatter } from '@shared/utils/responseFormatter';

export default class ImprovedCarController {
  constructor(private readonly service: ImprovedCarService) {}

  createCar: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      const car = await this.service.createCar(req.body, userId);
      
      return ResponseFormatter.created(res, car, 'Auto creado exitosamente');
    } catch (err) {
      next(err);
    }
  };

  getCarById: ExpressFunction = async (req, res, next) => {
    try {
      const car = await this.service.getCarById(Number(req.params.id));
      
      return ResponseFormatter.success(res, car, 'Auto obtenido exitosamente');
    } catch (err) {
      next(err);
    }
  };

  listCars: ExpressFunction = async (req, res, next) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Math.min(Number(req.query.limit) || 10, 50);
      const filters = {
        instructorId: req.query.instructorId ? Number(req.query.instructorId) : undefined,
        isActive: req.query.isActive === 'true' ? true : req.query.isActive === 'false' ? false : undefined,
        transmission: req.query.transmission as any,
        brand: req.query.brand as string
      };

      const result = await this.service.listCars(page, limit, filters);
      
      return ResponseFormatter.success(res, result, 'Autos obtenidos exitosamente');
    } catch (err) {
      next(err);
    }
  };

  updateCar: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      const car = await this.service.updateCar(Number(req.params.id), req.body, userId);
      
      return ResponseFormatter.success(res, car, 'Auto actualizado exitosamente');
    } catch (err) {
      next(err);
    }
  };

  deleteCar: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      await this.service.deleteCar(Number(req.params.id), userId);
      
      return ResponseFormatter.success(res, null, 'Auto eliminado exitosamente');
    } catch (err) {
      next(err);
    }
  };

  getCarsByInstructor: ExpressFunction = async (req, res, next) => {
    try {
      const cars = await this.service.getCarsByInstructor(Number(req.params.instructorId));
      
      return ResponseFormatter.success(res, cars, 'Autos del instructor obtenidos exitosamente');
    } catch (err) {
      next(err);
    }
  };

  toggleCarStatus: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      const car = await this.service.toggleCarStatus(Number(req.params.id), userId);
      
      return ResponseFormatter.success(res, car, 'Estado del auto actualizado exitosamente');
    } catch (err) {
      next(err);
    }
  };
}