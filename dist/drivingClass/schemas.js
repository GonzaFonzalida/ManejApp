"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateDrivingClassSchema = exports.createDrivingClassSchema = void 0;
const zod_1 = require("zod");
exports.createDrivingClassSchema = zod_1.z.object({
    instructorId: zod_1.z.number().int().positive(),
    studentId: zod_1.z.number().int().positive(),
    date: zod_1.z
        .string()
        .refine((val) => !isNaN(Date.parse(val)), { message: "Invalid date format, must be ISO-8601" }), // ejemplo: "2025-08-17T15:00:00.000Z"
    duration: zod_1.z.number().int().positive().max(180), // no más de 3h
    status: zod_1.z.enum(["scheduled", "completed", "canceled"]),
});
exports.updateDrivingClassSchema = zod_1.z.object({
    date: zod_1.z
        .string()
        .optional()
        .refine((val) => !val || !isNaN(Date.parse(val)), { message: "Invalid date format, must be ISO-8601" }),
    duration: zod_1.z.number().int().positive().max(180).optional(),
    status: zod_1.z.enum(["scheduled", "completed", "canceled"]).optional(),
});
