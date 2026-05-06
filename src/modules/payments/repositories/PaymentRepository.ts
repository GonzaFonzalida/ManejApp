import { Payment } from "../payment.types";

export type PaymentCreateRepoInput = {
  amount: number;
  paymentMethod: string;
  drivingClassId: number;
  provider?: string | null;
  preferenceId?: string | null;
  paymentId?: string | null;
  externalReference?: string | null;
  rawPayload?: unknown;
  appCommission?: number | null;
  instructorAmount?: number | null;
  commissionRate?: number | null;
  instructorPayoutStatus?: string | null;
  instructorPayoutEligibleAt?: Date | null;
  mpTransactionAmount?: number | null;
};

export type MercadoPagoPaymentPatch = {
  preferenceId?: string | null;
  paymentId?: string | null;
  externalReference?: string | null;
  status?: string;
  rawPayload?: unknown;
  paymentMethod?: string;
  appCommission?: number | null;
  instructorAmount?: number | null;
  commissionRate?: number | null;
  mpTransactionAmount?: number | null;
  instructorPayoutStatus?: string | null;
  instructorPayoutEligibleAt?: Date | null;
};

export interface PaymentRepository {
  createPayment(data: PaymentCreateRepoInput): Promise<Payment>;

  getPaymentById(id: number): Promise<Payment | null>;

  getPaymentsByDrivingClass(drivingClassId: number): Promise<Payment[]>;

  updatePaymentStatus(id: number, status: string): Promise<Payment>;

  listPayments(filter?: { status?: string }): Promise<Payment[]>;

  updatePaymentWithMercadoPagoData(id: number, data: MercadoPagoPaymentPatch): Promise<Payment>;

  getPaymentByExternalReference(externalReference: string): Promise<Payment | null>;

  getPaymentByPreferenceId(preferenceId: string): Promise<Payment | null>;

  getPaymentByPaymentId(paymentId: string): Promise<Payment | null>;
}
