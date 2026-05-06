import { z } from "zod";

export const loginSchema = z.object({
  email: z
    .string()
    .email()
    .transform((s) => s.trim().toLowerCase()),
  password: z.string().min(6),
});

export const googleLoginSchema = z.object({
  idToken: z.string().min(1, "Token de Google requerido"),
});

export const appleLoginSchema = z.object({
  identityToken: z.string().min(1, "identityToken de Apple requerido"),
  rawNonce: z.string().min(1, "rawNonce requerido").max(512),
  givenName: z.string().max(100).optional(),
  familyName: z.string().max(100).optional(),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1).optional(),
});

export const revokeSessionSchema = z.object({
  sessionId: z.string().uuid(),
});
