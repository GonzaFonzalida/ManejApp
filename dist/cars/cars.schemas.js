"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateCarSchema = exports.carSchema = void 0;
const zod_1 = require("zod");
exports.carSchema = zod_1.z.object({
    brand: zod_1.z.string().min(2, "La marca es requerida"),
    model: zod_1.z.string().min(1, "El modelo es requerido"),
    instructorId: zod_1.z.number().int(),
    year: zod_1.z.number().int().gte(1990).lte(new Date().getFullYear()),
    licensePlate: zod_1.z.string().min(5, "La patente es requerida"),
    transmission: zod_1.z.enum(["MANUAL", "AUTOMATIC"]),
});
exports.updateCarSchema = exports.carSchema.partial();
