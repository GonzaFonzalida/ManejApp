"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getUserByRoleSchema = exports.loginSchema = exports.registerSchema = exports.userSchema = void 0;
const zod_1 = require("zod");
exports.userSchema = zod_1.z.object({
    name: zod_1.z.string().min(1, "El nombre es requerido"),
    email: zod_1.z.string().email("Correo electrónico inválido"),
    password: zod_1.z.string().min(6, "La contraseña debe tener al menos 6 caracteres"),
    age: zod_1.z.number().int().positive().optional(),
});
exports.registerSchema = zod_1.z.object({
    name: zod_1.z.string().min(1, "El nombre es requerido"),
    surname: zod_1.z.string().min(1, "El apellido es requerido"),
    email: zod_1.z.email("Correo electrónico inválido"),
    dni: zod_1.z.string().min(1, "El DNI es requerido"),
    password: zod_1.z.string().min(8, "La contraseña debe tener al menos 8 caracteres"),
    birthDate: zod_1.z.string().min(1, "La fecha de nacimiento es requerida"),
});
exports.loginSchema = zod_1.z.object({
    email: zod_1.z.email("Correo electrónico inválido").optional(),
    dni: zod_1.z.string().min(1, "El DNI es requerido").optional(),
    password: zod_1.z.string().min(8, "La contraseña debe tener al menos 8 caracteres"),
}).refine((data) => !!data.email || !!data.dni, { message: "Debe proporcionar un correo electrónico o un DNI", path: ["email", "dni"] });
exports.getUserByRoleSchema = zod_1.z.object({
    role: zod_1.z.enum(["STUDENT", "INSTRUCTOR", "ADMIN"]),
});
