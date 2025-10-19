import { z } from 'zod';

export const createCarSchema = z.object({
  body: z.object({
    brand: z.string().min(2).max(50).regex(/^[a-zA-Z\s]+$/, 'Solo letras y espacios'),
    model: z.string().min(1).max(50),
    instructorId: z.number().int().positive(),
    year: z.number().int().min(1990).max(new Date().getFullYear() + 1),
    licensePlate: z.string().min(6).max(10).regex(/^[A-Z0-9\s-]+$/i, 'Formato de patente inválido'),
    transmission: z.enum(['MANUAL', 'AUTOMATIC']),
    isActive: z.boolean().optional().default(true),
  })
});

export const updateCarSchema = z.object({
  body: createCarSchema.shape.body.partial()
});

export const carFiltersSchema = z.object({
  query: z.object({
    page: z.string().transform(val => parseInt(val)).pipe(z.number().int().min(1)).optional(),
    limit: z.string().transform(val => parseInt(val)).pipe(z.number().int().min(1).max(50)).optional(),
    instructorId: z.string().transform(val => parseInt(val)).pipe(z.number().int().positive()).optional(),
    isActive: z.enum(['true', 'false']).optional(),
    transmission: z.enum(['MANUAL', 'AUTOMATIC']).optional(),
    brand: z.string().min(1).optional(),
  })
});

export const carIdSchema = z.object({
  params: z.object({
    id: z.string().transform(val => parseInt(val)).pipe(z.number().int().positive())
  })
});