"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.assignCarSchema = exports.updateInstructorSchema = exports.createInstructorSchema = void 0;
const zod_1 = require("zod");
exports.createInstructorSchema = zod_1.z.object({
    userId: zod_1.z.number()
        .int()
        .positive({ message: "El ID de usuario debe ser un número positivo" }),
    licenseNumber: zod_1.z.string()
        .min(5, { message: "El número de licencia debe tener al menos 5 caracteres" })
        .max(20, { message: "El número de licencia no puede exceder 20 caracteres" }),
    experienceYears: zod_1.z.number()
        .int()
        .min(0, { message: "La experiencia no puede ser negativa" })
        .max(50, { message: "La experiencia no puede ser mayor a 50 años" }),
    carId: zod_1.z.number()
        .int()
        .positive({ message: "El ID de auto debe ser un número positivo" })
        .optional(),
});
// Para actualizar datos del instructor
exports.updateInstructorSchema = zod_1.z.object({
    licenseNumber: zod_1.z.string()
        .min(5)
        .max(20)
        .optional(),
    experienceYears: zod_1.z.number()
        .int()
        .min(0)
        .max(50)
        .optional(),
    available: zod_1.z.boolean().optional(),
    isValid: zod_1.z.boolean().optional(),
    carId: zod_1.z.number().int().positive().optional(),
});
// Para asignar un auto a un instructor
exports.assignCarSchema = zod_1.z.object({
    instructorId: zod_1.z.number()
        .int()
        .positive({ message: "El ID del instructor debe ser positivo" }),
    carId: zod_1.z.number()
        .int()
        .positive({ message: "El ID del auto debe ser positivo" }),
});
