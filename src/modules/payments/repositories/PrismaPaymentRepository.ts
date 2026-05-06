import { PaymentRepository, MercadoPagoPaymentPatch, PaymentCreateRepoInput } from "./PaymentRepository";
import { Payment } from "../payment.types";
import { prisma } from "@config/prismaClient";
import { Prisma } from "@prisma/client";

export default class PrismaPaymentRepository implements PaymentRepository {
  private prisma = prisma;

  async createPayment(data: PaymentCreateRepoInput): Promise<Payment> {
    const result = await this.prisma.payment.create({
      data: {
        amount: data.amount,
        paymentMethod: data.paymentMethod,
        drivingClassId: data.drivingClassId,
        provider: data.provider ?? undefined,
        preferenceId: data.preferenceId,
        paymentId: data.paymentId,
        externalReference: data.externalReference,
        rawPayload: data.rawPayload ? (data.rawPayload as object) : undefined,
        appCommission: data.appCommission ?? undefined,
        instructorAmount: data.instructorAmount ?? undefined,
        commissionRate: data.commissionRate ?? undefined,
        instructorPayoutStatus: data.instructorPayoutStatus ?? undefined,
        instructorPayoutEligibleAt: data.instructorPayoutEligibleAt ?? undefined,
        mpTransactionAmount: data.mpTransactionAmount ?? undefined,
      },
    });
    return {
      ...result,
      createdAt: new Date(result.createdAt),
      updatedAt: new Date(result.updatedAt),
    };
  }

  async getPaymentById(id: number): Promise<Payment | null> {
    const result = await this.prisma.payment.findUnique({
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

  async updatePaymentStatus(id: number, status: string): Promise<Payment> {
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

  async listPayments(filter?: { status?: string }): Promise<Payment[]> {
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

  async updatePaymentWithMercadoPagoData(id: number, data: MercadoPagoPaymentPatch): Promise<Payment> {
    const patch: Prisma.PaymentUpdateInput = {};

    if (data.preferenceId !== undefined) patch.preferenceId = data.preferenceId;
    if (data.paymentId !== undefined) patch.paymentId = data.paymentId;
    if (data.externalReference !== undefined) patch.externalReference = data.externalReference;
    if (data.status !== undefined) patch.status = data.status;
    if (data.rawPayload !== undefined) patch.rawPayload = data.rawPayload as object;
    if (data.paymentMethod !== undefined) patch.paymentMethod = data.paymentMethod;
    if (data.appCommission !== undefined) patch.appCommission = data.appCommission;
    if (data.instructorAmount !== undefined) patch.instructorAmount = data.instructorAmount;
    if (data.commissionRate !== undefined) patch.commissionRate = data.commissionRate;
    if (data.mpTransactionAmount !== undefined) patch.mpTransactionAmount = data.mpTransactionAmount;
    if (data.instructorPayoutStatus !== undefined && data.instructorPayoutStatus !== null) {
      patch.instructorPayoutStatus = data.instructorPayoutStatus;
    }
    if (data.instructorPayoutEligibleAt !== undefined) {
      patch.instructorPayoutEligibleAt = data.instructorPayoutEligibleAt;
    }

    const result = await this.prisma.payment.update({
      where: { id },
      data: patch,
    });
    return {
      ...result,
      createdAt: new Date(result.createdAt),
      updatedAt: new Date(result.updatedAt),
    };
  }

  async getPaymentByExternalReference(externalReference: string): Promise<Payment | null> {
    const result = await this.prisma.payment.findFirst({
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
    const result = await this.prisma.payment.findFirst({
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
    const result = await this.prisma.payment.findFirst({
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
