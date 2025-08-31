"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updatePaymentWithMercadoPagoSchema = exports.mercadoPagoWebhookSchema = exports.createMercadoPagoPreferenceSchema = exports.paymentIdSchema = exports.updatePaymentStatusSchema = exports.createPaymentSchema = void 0;
const zod_1 = require("zod");
exports.createPaymentSchema = zod_1.z.object({
    amount: zod_1.z.number()
        .positive({ message: "El monto debe ser un número positivo" }),
    paymentMethod: zod_1.z.enum(["cash", "card", "transfer", "mercadopago"], {
        message: "El método de pago debe ser: cash, card, transfer o mercadopago"
    }),
    drivingClassId: zod_1.z.number()
        .int()
        .positive({ message: "El ID de la clase de conducción debe ser un número positivo" }),
    // Optional Mercado Pago fields
    preferenceId: zod_1.z.string().optional(),
    paymentId: zod_1.z.string().optional(),
    externalReference: zod_1.z.string().optional(),
});
exports.updatePaymentStatusSchema = zod_1.z.object({
    status: zod_1.z.enum(["pending", "paid", "failed"]),
});
exports.paymentIdSchema = zod_1.z.object({
    id: zod_1.z.number()
        .int()
        .positive({ message: "El ID del pago debe ser un número positivo" }),
});
// Mercado Pago specific schemas
exports.createMercadoPagoPreferenceSchema = zod_1.z.object({
    amount: zod_1.z.number()
        .positive({ message: "El monto debe ser un número positivo" }),
    drivingClassId: zod_1.z.number()
        .int()
        .positive({ message: "El ID de la clase de conducción debe ser un número positivo" }),
    description: zod_1.z.string()
        .min(1, { message: "La descripción es obligatoria" })
        .max(255, { message: "La descripción no puede exceder 255 caracteres" }),
});
exports.mercadoPagoWebhookSchema = zod_1.z.object({
    id: zod_1.z.string(),
    type: zod_1.z.string(),
    data: zod_1.z.object({
        id: zod_1.z.string(),
    }),
});
exports.updatePaymentWithMercadoPagoSchema = zod_1.z.object({
    preferenceId: zod_1.z.string().optional(),
    paymentId: zod_1.z.string().optional(),
    externalReference: zod_1.z.string().optional(),
    status: zod_1.z.enum(["pending", "paid", "failed"]).optional(),
});
