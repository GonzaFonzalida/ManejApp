import { prisma } from "@config/prismaClient";
import { CarRepository } from "./CarRepository";
import { CarDTO, CarWithId } from "../cars.types";

export class PrismaCarRepository implements CarRepository {
  async create(data: CarDTO): Promise<CarWithId> {
    const car = await prisma.car.create({ data });
    return car;
  }

  async findById(id: number): Promise<CarWithId | null> {
    return prisma.car.findUnique({ where: { id } });
  }

  async findAll(): Promise<CarWithId[]> {
    return prisma.car.findMany();
  }

  async update(id: number, data: Partial<CarDTO>): Promise<CarWithId | null> {
    try {
      return await prisma.car.update({ where: { id }, data });
    } catch {
      return null;
    }
  }

  async delete(id: number): Promise<boolean> {
    try {
      await prisma.car.delete({ where: { id } });
      return true;
    } catch {
      return false;
    }
  }
}
