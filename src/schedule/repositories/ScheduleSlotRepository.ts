import { ScheduleSlot } from "@prisma/client";

export interface ScheduleSlotRepository {
  create(data: Omit<ScheduleSlot, "id" | "createdAt" | "updatedAt">): Promise<ScheduleSlot>;
  findById(id: string): Promise<ScheduleSlot | null>;
  findByInstructor(instructorId: number): Promise<ScheduleSlot[]>;
  findAvailableByInstructor(instructorId: number, startDate?: Date, endDate?: Date): Promise<ScheduleSlot[]>;
  update(id: string, data: Partial<ScheduleSlot>): Promise<ScheduleSlot>;
  delete(id: string): Promise<void>;
  bookSlot(id: string, drivingClassId: number): Promise<ScheduleSlot>;
  cancelBooking(id: string): Promise<ScheduleSlot>;
}