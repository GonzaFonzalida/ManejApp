import { z } from "zod";

export const createInstructorSchema = z.object({
  userId: z.number()
    .int()
    .positive({ message: "El ID de usuario debe ser un número positivo" }),
  
  licenseNumber: z.string()
    .min(5, { message: "El número de licencia debe tener al menos 5 caracteres" })
    .max(20, { message: "El número de licencia no puede exceder 20 caracteres" }),

  experienceYears: z.number()
    .int()
    .min(0, { message: "La experiencia no puede ser negativa" })
    .max(50, { message: "La experiencia no puede ser mayor a 50 años" }),

  carId: z.number()
    .int()
    .positive({ message: "El ID de auto debe ser un número positivo" })
    .optional(),
});

// Para actualizar datos del instructor
export const updateInstructorSchema = z.object({
  licenseNumber: z.string()
    .min(5)
    .max(20)
    .optional(),
  
  experienceYears: z.number()
    .int()
    .min(0)
    .max(50)
    .optional(),
  
  available: z.boolean().optional(),
  isValid: z.boolean().optional(),
  carId: z.number().int().positive().optional(),
});

// Para asignar un auto a un instructor
export const assignCarSchema = z.object({
  instructorId: z.number()
    .int()
    .positive({ message: "El ID del instructor debe ser positivo" }),
  
  carId: z.number()
    .int()
    .positive({ message: "El ID del auto debe ser positivo" }),
});
