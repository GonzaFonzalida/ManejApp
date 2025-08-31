import { z } from "zod";

export const createPaymentSchema = z.object({
  amount: z.number()
    .positive({ message: "El monto debe ser un número positivo" }),

  paymentMethod: z.enum(["cash", "card", "transfer", "mercadopago"], {
    message: "El método de pago debe ser: cash, card, transfer o mercadopago"
  }),

  drivingClassId: z.number()
    .int()
    .positive({ message: "El ID de la clase de conducción debe ser un número positivo" }),

  // Optional Mercado Pago fields
  preferenceId: z.string().optional(),
  paymentId: z.string().optional(),
  externalReference: z.string().optional(),
});

export const updatePaymentStatusSchema = z.object({
  status: z.enum(["pending", "paid", "failed"]),
});

export const paymentIdSchema = z.object({
  id: z.number()
    .int()
    .positive({ message: "El ID del pago debe ser un número positivo" }),
});

// Mercado Pago specific schemas
export const createMercadoPagoPreferenceSchema = z.object({
  amount: z.number()
    .positive({ message: "El monto debe ser un número positivo" }),
  drivingClassId: z.number()
    .int()
    .positive({ message: "El ID de la clase de conducción debe ser un número positivo" }),
  description: z.string()
    .min(1, { message: "La descripción es obligatoria" })
    .max(255, { message: "La descripción no puede exceder 255 caracteres" }),
});

export const mercadoPagoWebhookSchema = z.object({
  id: z.string(),
  type: z.string(),
  data: z.object({
    id: z.string(),
  }),
});

export const updatePaymentWithMercadoPagoSchema = z.object({
  preferenceId: z.string().optional(),
  paymentId: z.string().optional(),
  externalReference: z.string().optional(),
  status: z.enum(["pending", "paid", "failed"]).optional(),
});