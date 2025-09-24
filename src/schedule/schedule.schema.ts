import { z } from "zod";

export const createSlotSchema = z.object({
  instructorId: z.number().int().positive("Instructor ID debe ser positivo"),
  startTime: z.string().datetime("Fecha de inicio inválida"),
  endTime: z.string().datetime("Fecha de fin inválida"),
}).refine(data => new Date(data.startTime) < new Date(data.endTime), {
  message: "La hora de fin debe ser posterior a la de inicio",
  path: ["endTime"],
});

export const reserveSlotSchema = z.object({
  // No body required, slotId in params
});