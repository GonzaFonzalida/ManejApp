import { z } from 'zod';
import { Role } from '@prisma/client';

export const sendToUserSchema = z.object({
  userId: z.number().int().positive(),
  title: z.string().min(1).max(100),
  body: z.string().min(1).max(500),
});

export const sendToRoleSchema = z.object({
  role: z.nativeEnum(Role),
  title: z.string().min(1).max(100),
  body: z.string().min(1).max(500),
});

export const broadcastSchema = z.object({
  title: z.string().min(1).max(100),
  body: z.string().min(1).max(500),
});

export const registerTokenSchema = z.object({
  token: z.string().min(1),
});

export type SendToUserInput = z.infer<typeof sendToUserSchema>;
export type SendToRoleInput = z.infer<typeof sendToRoleSchema>;
export type BroadcastInput = z.infer<typeof broadcastSchema>;
export type RegisterTokenInput = z.infer<typeof registerTokenSchema>;