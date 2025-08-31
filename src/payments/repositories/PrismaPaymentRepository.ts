import { PaymentRepository } from "./PaymentRepository";
import { Payment } from "../payment.types";
import * as config from "@config/prismaClient";

export default class PrismaPaymentRepository implements PaymentRepository {
  private prisma = config.prisma;

  async createPayment(data: {
    amount: number;
    paymentMethod: string;
    drivingClassId: number;
    preferenceId?: string;
    paymentId?: string;
    externalReference?: string;
  }): Promise<Payment> {
    const result = await (this.prisma as any).payment.create({
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

  async getPaymentById(id: number): Promise<Payment | null> {
    const result = await (this.prisma as any).payment.findUnique({
      where: { id },
      include: { drivingClass: true },
    });
    if (!result) return null;
    return {
      ...result,
      createdAt: new Date(result.createdAt),
      updatedAt: new Date(result.updatedAt),
    };
  }

  async getPaymentsByDrivingClass(drivingClassId: number): Promise<Payment[]> {
    const results = await (this.prisma as any).payment.findMany({
      where: { drivingClassId },
      include: { drivingClass: true },
    });
    return results.map((result: any) => ({
      ...result,
      createdAt: new Date(result.createdAt),
      updatedAt: new Date(result.updatedAt),
    }));
  }

  async updatePaymentStatus(id: number, status: string): Promise<Payment> {
    const result = await (this.prisma as any).payment.update({
      where: { id },
      data: { status },
    });
    return {
      ...result,
      createdAt: new Date(result.createdAt),
      updatedAt: new Date(result.updatedAt),
    };
  }

  async listPayments(filter?: { status?: string }): Promise<Payment[]> {
    const results = await (this.prisma as any).payment.findMany({
      where: filter,
      include: { drivingClass: true },
    });
    return results.map((result: any) => ({
      ...result,
      createdAt: new Date(result.createdAt),
      updatedAt: new Date(result.updatedAt),
    }));
  }

  // Mercado Pago specific methods
  async updatePaymentWithMercadoPagoData(id: number, data: {
    preferenceId?: string;
    paymentId?: string;
    externalReference?: string;
    status?: string;
  }): Promise<Payment> {
    const result = await (this.prisma as any).payment.update({
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

  async getPaymentByExternalReference(externalReference: string): Promise<Payment | null> {
    const result = await (this.prisma as any).payment.findFirst({
      where: { externalReference },
      include: { drivingClass: true },
    });
    if (!result) return null;
    return {
      ...result,
      createdAt: new Date(result.createdAt),
      updatedAt: new Date(result.updatedAt),
    };
  }

  async getPaymentByPreferenceId(preferenceId: string): Promise<Payment | null> {
    const result = await (this.prisma as any).payment.findFirst({
      where: { preferenceId },
      include: { drivingClass: true },
    });
    if (!result) return null;
    return {
      ...result,
      createdAt: new Date(result.createdAt),
      updatedAt: new Date(result.updatedAt),
    };
  }

  async getPaymentByPaymentId(paymentId: string): Promise<Payment | null> {
    const result = await (this.prisma as any).payment.findFirst({
      where: { paymentId },
      include: { drivingClass: true },
    });
    if (!result) return null;
    return {
      ...result,
      createdAt: new Date(result.createdAt),
      updatedAt: new Date(result.updatedAt),
    };
  }
}