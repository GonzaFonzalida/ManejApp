"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const prismaClient_1 = require("../../config/prismaClient");
class PrismaPaymentRepository {
    prisma = prismaClient_1.prisma;
    async createPayment(data) {
        const result = await this.prisma.payment.create({
            data: {
                amount: data.amount,
                paymentMethod: data.paymentMethod,
                drivingClassId: data.drivingClassId,
                preferenceId: data.preferenceId,
                paymentId: data.paymentId,
                externalReference: data.externalReference,
            },
        });
        return {
            ...result,
            createdAt: new Date(result.createdAt),
            updatedAt: new Date(result.updatedAt),
        };
    }
    async getPaymentById(id) {
        const result = await this.prisma.payment.findUnique({
            where: { id },
            include: { drivingClass: true },
        });
        if (!result)
            return null;
        return {
            ...result,
            createdAt: new Date(result.createdAt),
            updatedAt: new Date(result.updatedAt),
        };
    }
    async getPaymentsByDrivingClass(drivingClassId) {
        const results = await this.prisma.payment.findMany({
            where: { drivingClassId },
            include: { drivingClass: true },
        });
        return results.map((result) => ({
            ...result,
            createdAt: new Date(result.createdAt),
            updatedAt: new Date(result.updatedAt),
        }));
    }
    async updatePaymentStatus(id, status) {
        const result = await this.prisma.payment.update({
            where: { id },
            data: { status },
        });
        return {
            ...result,
            createdAt: new Date(result.createdAt),
            updatedAt: new Date(result.updatedAt),
        };
    }
    async listPayments(filter) {
        const results = await this.prisma.payment.findMany({
            where: filter,
            include: { drivingClass: true },
        });
        return results.map((result) => ({
            ...result,
            createdAt: new Date(result.createdAt),
            updatedAt: new Date(result.updatedAt),
        }));
    }
    // Mercado Pago specific methods
    async updatePaymentWithMercadoPagoData(id, data) {
        const result = await this.prisma.payment.update({
            where: { id },
            data: {
                preferenceId: data.preferenceId,
                paymentId: data.paymentId,
                externalReference: data.externalReference,
                status: data.status,
            },
        });
        return {
            ...result,
            createdAt: new Date(result.createdAt),
            updatedAt: new Date(result.updatedAt),
        };
    }
    async getPaymentByExternalReference(externalReference) {
        const result = await this.prisma.payment.findFirst({
            where: { externalReference },
            include: { drivingClass: true },
        });
        if (!result)
            return null;
        return {
            ...result,
            createdAt: new Date(result.createdAt),
            updatedAt: new Date(result.updatedAt),
        };
    }
    async getPaymentByPreferenceId(preferenceId) {
        const result = await this.prisma.payment.findFirst({
            where: { preferenceId },
            include: { drivingClass: true },
        });
        if (!result)
            return null;
        return {
            ...result,
            createdAt: new Date(result.createdAt),
            updatedAt: new Date(result.updatedAt),
        };
    }
    async getPaymentByPaymentId(paymentId) {
        const result = await this.prisma.payment.findFirst({
            where: { paymentId },
            include: { drivingClass: true },
        });
        if (!result)
            return null;
        return {
            ...result,
            createdAt: new Date(result.createdAt),
            updatedAt: new Date(result.updatedAt),
        };
    }
}
exports.default = PrismaPaymentRepository;
