import { z } from 'zod';

export const createPaymentSchema = z.object({
  body: z.object({
    amount: z.number().positive().max(1000000),
    paymentMethod: z.enum(['cash', 'card', 'transfer', 'mercadopago']),
    drivingClassId: z.number().int().positive(),
    preferenceId: z.string().optional(),
    paymentId: z.string().optional(),
    externalReference: z.string().optional(),
  })
});

export const refundPaymentSchema = z.object({
  body: z.object({
    reason: z.string().min(10).max(500),
    amount: z.number().positive().optional(), // Partial refund
  })
});

export const updatePaymentStatusSchema = z.object({
  body: z.object({
    status: z.enum(['pending', 'paid', 'failed', 'cancelled', 'refunded']),
  })
});

export const createMercadoPagoPreferenceSchema = z.object({
  body: z.object({
    amount: z.number().positive().max(1000000),
    description: z.string().min(1).max(255),
    drivingClassId: z.number().int().positive(),
    payerEmail: z.string().email().optional(),
  })
});

export const paymentReportSchema = z.object({
  query: z.object({
    startDate: z.string().datetime().optional(),
    endDate: z.string().datetime().optional(),
    status: z.enum(['pending', 'paid', 'failed', 'cancelled', 'refunded']).optional(),
    method: z.enum(['cash', 'card', 'transfer', 'mercadopago']).optional(),
  })
});

export const webhookSchema = z.object({
  body: z.object({
    id: z.string(),
    type: z.string(),
    data: z.object({
      id: z.string(),
    }),
    date_created: z.string().optional(),
    user_id: z.string().optional(),
  })
});