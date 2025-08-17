import { z } from "zod";

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

export const refreshSchema = z.object({}); // no body; cookie httpOnly

export const revokeSessionSchema = z.object({
  sessionId: z.string().uuid(),
});
