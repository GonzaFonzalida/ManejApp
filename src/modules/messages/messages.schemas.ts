import { z } from "zod";

/** Cuerpo JSON plano para POST /messages/send (validateZodSchema parsea req.body). */
export const sendMessageSchema = z.object({
  receiverId: z.coerce.number().int().positive("receiverId debe ser un número entero positivo"),
  content: z.string().min(1, "El contenido no puede estar vacío").max(1000, "El mensaje no puede exceder 1000 caracteres"),
});

/** Params de rutas /conversations/:conversationId/... */
export const conversationIdParamSchema = z.object({
  conversationId: z
    .string()
    .regex(/^\d+$/, "conversationId debe ser un número")
    .transform((val: string) => parseInt(val, 10)),
});

export type SendMessageInput = z.infer<typeof sendMessageSchema>;
export type ConversationIdParamInput = z.infer<typeof conversationIdParamSchema>;