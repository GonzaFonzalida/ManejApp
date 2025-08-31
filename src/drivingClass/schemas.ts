import { z } from "zod";

export const createDrivingClassSchema = z.object({
  instructorId: z.number().int().positive(),
  studentId: z.number().int().positive(),
  date: z
    .string()
    .refine(
      (val) => !isNaN(Date.parse(val)), 
      { message: "Invalid date format, must be ISO-8601" }
    ), // ejemplo: "2025-08-17T15:00:00.000Z"
  duration: z.number().int().positive().max(180), // no más de 3h
  status: z.enum(["scheduled", "completed", "canceled"]),
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
  status: z.enum(["scheduled", "completed", "canceled"]).optional(),
});
