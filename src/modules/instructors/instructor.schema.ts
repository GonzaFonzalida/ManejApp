import { z } from "zod";

export const createInstructorSchema = z.object({
  userId: z.number()
    .int()
    .positive({ message: "El ID de usuario debe ser un número positivo" }),

  /** Opcional en registro: la licencia se valida con documento `licenciaImg` + revisión admin. */
  licenseNumber: z.preprocess(
    (v) => (v === "" || v === null || v === undefined ? undefined : String(v).trim()),
    z.string().min(5).max(20).optional()
  ),

  experienceYears: z.number()
    .int()
    .min(0, { message: "La experiencia no puede ser negativa" })
    .max(50, { message: "La experiencia no puede ser mayor a 50 años" }),

  carId: z.number()
    .int()
    .positive({ message: "El ID de auto debe ser un número positivo" })
    .optional(),

  hourlyRate: z.number().positive().optional(),
});

// Para actualizar datos del instructor
export const updateInstructorSchema = z.object({
  licenseNumber: z.preprocess(
    (v) => (v === "" || v === null || v === undefined ? undefined : String(v).trim()),
    z.string().min(5).max(20).optional()
  ),
  experienceYears: z.number().int().min(0).max(50).optional(),
  available: z.boolean().optional(),
  isValid: z.boolean().optional(),
  carId: z.number().int().positive().optional(),
  hourlyRate: z.number().positive().optional(),
  // MVP profile fields
  bio: z.string().max(5000).optional().nullable(),
  categories: z.array(z.string()).optional().nullable(),
  photos: z.array(z.string().url()).optional().nullable(),
  isListed: z.boolean().optional(),
  lat: z.number().optional().nullable(),
  lng: z.number().optional().nullable(),
  geohash: z.string().max(20).optional().nullable(),
  addressText: z.string().max(500).optional().nullable(),
});

// PATCH /me/listed — explicit boolean (required in body)
export const patchListedSchema = z.object({
  isListed: z.boolean(),
});

export const uploadDocumentSchema = z.object({
  documentType: z.enum([
    "dobleComandoImg",
    "seguroImg",
    "vtvImg",
    "reincidenciaImg",
    "licenciaImg"
  ]),
  image: z.string().min(1, "La imagen en base64 es requerida"),
  mimeType: z.string().optional(),
});

// GET /nearby — query params (lat/lng required; radiusKm, limit optional with defaults)
export const nearbyQuerySchema = z.object({
  lat: z.coerce.number().min(-90, "lat debe estar entre -90 y 90").max(90, "lat debe estar entre -90 y 90"),
  lng: z.coerce.number().min(-180, "lng debe estar entre -180 y 180").max(180, "lng debe estar entre -180 y 180"),
  radiusKm: z.coerce.number().min(0.5, "radiusKm mínimo 0.5").max(50, "radiusKm máximo 50").default(5),
  limit: z.coerce.number().int().min(1, "limit mínimo 1").max(200, "limit máximo 200").default(50),
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
