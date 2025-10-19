import { CarRepository } from './repositories/CarRepository';
import { CarDTO, CarWithId } from './cars.types';
import CustomizedError from '@shared/classes/CustomizedError';
import { AuditService, AuditAction } from '@shared/services/AuditService';
import { prisma } from '@config/prismaClient';

export interface CarFilters {
  instructorId?: number;
  isActive?: boolean;
  transmission?: 'MANUAL' | 'AUTOMATIC';
  brand?: string;
}

export interface PaginatedCars {
  cars: CarWithId[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export default class ImprovedCarService {
  constructor(private readonly carRepo: CarRepository) {}

  async createCar(data: CarDTO, userId?: number): Promise<CarWithId> {
    return await prisma.$transaction(async (tx) => {
      // Validate instructor exists and is active
      const instructor = await tx.instructor.findUnique({
        where: { id: data.instructorId },
        include: { user: true }
      });

      if (!instructor) {
        throw new CustomizedError('Instructor no encontrado', 404);
      }

      if (!instructor.isValid) {
        throw new CustomizedError('El instructor no está activo', 400);
      }

      // Check for duplicate license plate
      const existingCar = await tx.car.findUnique({
        where: { licensePlate: data.licensePlate }
      });

      if (existingCar) {
        throw new CustomizedError('Ya existe un auto con esta patente', 409);
      }

      const car = await this.carRepo.create(data);

      // Audit log
      AuditService.logUserAction(
        userId || instructor.userId,
        AuditAction.CREATE,
        'car',
        car.id,
        { licensePlate: data.licensePlate, brand: data.brand, model: data.model }
      );

      return car;
    });
  }

  async getCarById(id: number): Promise<CarWithId> {
    const car = await this.carRepo.findById(id);
    
    if (!car) {
      throw new CustomizedError('Auto no encontrado', 404);
    }

    return car;
  }

  async listCars(page = 1, limit = 10, filters: CarFilters = {}): Promise<PaginatedCars> {
    const cars = await this.carRepo.findMany(page, limit, filters);
    const total = await this.carRepo.count(filters);
    const totalPages = Math.ceil(total / limit);

    return {
      cars,
      total,
      page,
      limit,
      totalPages
    };
  }

  async updateCar(id: number, data: Partial<CarDTO>, userId?: number): Promise<CarWithId> {
    return await prisma.$transaction(async (tx) => {
      const existingCar = await this.getCarById(id);

      // If updating license plate, check for duplicates
      if (data.licensePlate && data.licensePlate !== existingCar.licensePlate) {
        const duplicate = await tx.car.findUnique({
          where: { licensePlate: data.licensePlate }
        });

        if (duplicate) {
          throw new CustomizedError('Ya existe un auto con esta patente', 409);
        }
      }

      // If updating instructor, validate exists and is active
      if (data.instructorId) {
        const instructor = await tx.instructor.findUnique({
          where: { id: data.instructorId }
        });

        if (!instructor || !instructor.isValid) {
          throw new CustomizedError('Instructor no válido', 400);
        }
      }

      const updatedCar = await this.carRepo.update(id, data);

      if (!updatedCar) {
        throw new CustomizedError('No se pudo actualizar el auto', 400);
      }

      // Audit log
      AuditService.logUserAction(
        userId || 0,
        AuditAction.UPDATE,
        'car',
        id,
        { changes: data, licensePlate: updatedCar.licensePlate }
      );

      return updatedCar;
    });
  }

  async deleteCar(id: number, userId?: number): Promise<void> {
    return await prisma.$transaction(async (tx) => {
      const car = await this.getCarById(id);

      // Check if car is being used in active driving classes
      const activeDrivingClasses = await tx.drivingClass.count({
        where: {
          instructor: {
            cars: {
              some: { id }
            }
          },
          status: 'scheduled'
        }
      });

      if (activeDrivingClasses > 0) {
        throw new CustomizedError('No se puede eliminar un auto con clases programadas', 400);
      }

      const success = await this.carRepo.delete(id);

      if (!success) {
        throw new CustomizedError('No se pudo eliminar el auto', 400);
      }

      // Audit log
      AuditService.logUserAction(
        userId || 0,
        AuditAction.DELETE,
        'car',
        id,
        { licensePlate: car.licensePlate, brand: car.brand, model: car.model }
      );
    });
  }

  async getCarsByInstructor(instructorId: number): Promise<CarWithId[]> {
    return this.carRepo.findMany(1, 100, { instructorId, isActive: true });
  }

  async toggleCarStatus(id: number, userId?: number): Promise<CarWithId> {
    const car = await this.getCarById(id);
    return this.updateCar(id, { isActive: !car.isActive }, userId);
  }
}