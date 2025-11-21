import { z } from "zod";

export const sendMessageSchema = z.object({
  body: z.object({
    receiverId: z.number().int().positive("receiverId debe ser un número entero positivo"),
    content: z.string().min(1, "El contenido no puede estar vacío").max(1000, "El mensaje no puede exceder 1000 caracteres"),
  }),
});

export const conversationIdSchema = z.object({
  params: z.object({
    conversationId: z.string().regex(/^\d+$/, "conversationId debe ser un número").transform((val: string) => parseInt(val)),
  }),
});

export type SendMessageInput = z.infer<typeof sendMessageSchema>;
export type ConversationIdInput = z.infer<typeof conversationIdSchema>;