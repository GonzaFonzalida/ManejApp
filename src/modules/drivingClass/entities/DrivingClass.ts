import { BookingStatus } from "@prisma/client";

export interface DrivingClass {
  id: number;
  instructorId: number;
  studentId: number;
  date: Date;
  notes: string | null;
  duration: number; // minutes
  status: BookingStatus;
  amount?: number | null;
  currency?: string | null;
  createdAt?: Date;
  updatedAt?: Date;
}
