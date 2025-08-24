import { z } from "zod";

export const carSchema = z.object({
  brand: z.string().min(2, "La marca es requerida"),
  model: z.string().min(1, "El modelo es requerido"),
  instructorId: z.number().int(),
  year: z.number().int().gte(1990).lte(new Date().getFullYear()),
  licensePlate: z.string().min(5, "La patente es requerida"),
  transmission: z.enum(["MANUAL", "AUTOMATIC"]),
});

export const updateCarSchema = carSchema.partial();
