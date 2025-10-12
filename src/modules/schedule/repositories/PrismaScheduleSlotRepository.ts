import { ScheduleSlotRepository } from "./ScheduleSlotRepository";
import { ScheduleSlot } from "@prisma/client";
import { prisma } from "@config/prismaClient";

export class PrismaScheduleSlotRepository implements ScheduleSlotRepository {
  async create(data: Omit<ScheduleSlot, "id" | "createdAt" | "updatedAt">): Promise<ScheduleSlot> {
    return prisma.scheduleSlot.create({ data });
  }

  async findById(id: string): Promise<ScheduleSlot | null> {
    return prisma.scheduleSlot.findUnique({ where: { id } });
  }

  async findByInstructor(instructorId: number): Promise<ScheduleSlot[]> {
    return prisma.scheduleSlot.findMany({
      where: { instructorId },
      orderBy: { startTime: "asc" },
    });
  }

  async findAvailableByInstructor(instructorId: number, startDate?: Date, endDate?: Date): Promise<ScheduleSlot[]> {
    const where: {
      instructorId: number;
      isBooked: boolean;
      startTime?: { gte?: Date; lte?: Date };
    } = {
      instructorId,
      isBooked: false,
    };
    if (startDate && endDate) {
      where.startTime = { gte: startDate, lte: endDate };
    } else if (startDate) {
      where.startTime = { gte: startDate };
    } else if (endDate) {
      where.startTime = { lte: endDate };
    }
    return prisma.scheduleSlot.findMany({
      where,
      orderBy: { startTime: "asc" },
    });
  }

  async update(id: string, data: Partial<ScheduleSlot>): Promise<ScheduleSlot> {
    return prisma.scheduleSlot.update({ where: { id }, data });
  }

  async delete(id: string): Promise<void> {
    await prisma.scheduleSlot.delete({ where: { id } });
  }

  async bookSlot(id: string, drivingClassId: number): Promise<ScheduleSlot> {
    return prisma.scheduleSlot.update({
      where: { id },
      data: { isBooked: true, drivingClassId },
    });
  }

  async cancelBooking(id: string): Promise<ScheduleSlot> {
    return prisma.scheduleSlot.update({
      where: { id },
      data: { isBooked: false, drivingClassId: null },
    });
  }
}