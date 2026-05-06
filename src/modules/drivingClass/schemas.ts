import { z } from "zod";

const bookingStatusValues = ["PENDING_PAYMENT", "CONFIRMED", "CANCELLED", "COMPLETED", "scheduled", "completed", "canceled"] as const;

export const createDrivingClassSchema = z.object({
  instructorId: z.number().int().positive(),
  studentId: z.number().int().positive(),
  date: z
    .string()
    .refine(
      (val) => !isNaN(Date.parse(val)),
      { message: "Invalid date format, must be ISO-8601" }
    ),
  duration: z.number().int().positive().max(180),
  status: z.enum(bookingStatusValues),
  amount: z.number().positive().optional(),
  currency: z.string().max(10).optional(),
});

export const updateDrivingClassSchema = z.object({
  date: z
    .string()
    .optional()
    .refine(
      (val) => !val || !isNaN(Date.parse(val)),
      { message: "Invalid date format, must be ISO-8601" }
    ),
  duration: z.number().int().positive().max(180).optional(),
  status: z.enum(bookingStatusValues).optional(),
  amount: z.number().positive().optional().nullable(),
  currency: z.string().max(10).optional().nullable(),
});
