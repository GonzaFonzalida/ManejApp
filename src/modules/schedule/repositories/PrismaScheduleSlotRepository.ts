import { ScheduleSlotRepository } from "./ScheduleSlotRepository";
import { ScheduleSlot, SlotStatus } from "@prisma/client";
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
      status: SlotStatus;
      startTime?: { gte?: Date; lte?: Date };
    } = {
      instructorId,
      status: SlotStatus.AVAILABLE,
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
      data: { status: SlotStatus.BOOKED, drivingClassId, heldUntil: null },
    });
  }

  async cancelBooking(id: string): Promise<ScheduleSlot> {
    return prisma.scheduleSlot.update({
      where: { id },
      data: { status: SlotStatus.AVAILABLE, drivingClassId: null, heldUntil: null },
    });
  }

  async tryHoldSlot(slotId: string, heldUntil: Date): Promise<number> {
    const now = new Date();
    const result = await prisma.scheduleSlot.updateMany({
      where: {
        id: slotId,
        OR: [
          { status: SlotStatus.AVAILABLE },
          { status: SlotStatus.HELD, heldUntil: { lt: now } },
        ],
      },
      data: { status: SlotStatus.HELD, heldUntil },
    });
    return result.count;
  }

  async findExpiredHeldSlots(): Promise<ScheduleSlot[]> {
    const now = new Date();
    return prisma.scheduleSlot.findMany({
      where: { status: SlotStatus.HELD, heldUntil: { lt: now } },
    });
  }
}