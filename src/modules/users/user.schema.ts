import { z } from "zod";
import { Request, Response, NextFunction } from "express";

export const userSchema = z.object({
  name: z.string().min(1, "El nombre es requerido"),
  email: z.string().email("Correo electrónico inválido"),
  password: z.string().min(6, "La contraseña debe tener al menos 6 caracteres"),
  age: z.number().int().positive().optional(),
});

export const registerSchema = z.object({
  name: z.string().min(1, "El nombre es requerido"),
  surname: z.string().min(1, "El apellido es requerido"),
  email: z.email("Correo electrónico inválido"),
  dni: z.string().min(1, "El DNI es requerido"),
  password: z.string().min(8, "La contraseña debe tener al menos 8 caracteres"),
  birthDate: z.string().min(1, "La fecha de nacimiento es requerida"),
  phoneNumber: z.string().optional(), // Optional for backwards compatibility
  location: z.string().optional(), // Optional for backwards compatibility
});

export const loginSchema = z.object({
  email: z.email("Correo electrónico inválido").optional(),
  dni: z.string().min(1, "El DNI es requerido").optional(),
  password: z.string().min(8, "La contraseña debe tener al menos 8 caracteres"),
}).refine(
  (data) => !!data.email || !!data.dni,
  { message: "Debe proporcionar un correo electrónico o un DNI", path: ["email", "dni"] }
);

export const getUserByRoleSchema = z.object({
  role: z.enum(["STUDENT", "INSTRUCTOR", "ADMIN"]),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email("Correo electrónico inválido"),
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1, "Token requerido"),
  newPassword: z.string().min(8, "La contraseña debe tener al menos 8 caracteres"),
});

export const studentProfilePatchSchema = z.object({
  experienceLevel: z.number().int().min(1).max(5),
});

/** POST /users/me/delete-account — la frase debe coincidir exactamente. */
export const deleteAccountSchema = z.object({
  confirmPhrase: z.literal("ELIMINAR"),
  password: z.string().optional(),
});

export type ParamsInput = z.infer<typeof getUserByRoleSchema>;
export type UserInput = z.infer<typeof userSchema>;
export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;

