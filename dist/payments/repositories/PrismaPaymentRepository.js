"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const config = __importStar(require("../../config/prismaClient"));
class PrismaPaymentRepository {
    prisma = config.prisma;
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
