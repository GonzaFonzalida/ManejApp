export interface Payment {
  id: number;
  amount: number;
  status: string;
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
  mpTransactionAmount?: number | null;
  instructorPayoutStatus?: string | null;
  instructorPayoutEligibleAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreatePaymentData {
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
}

export interface UpdatePaymentData {
  status?: string;
  // Mercado Pago specific fields
  preferenceId?: string | null;
  paymentId?: string | null;
  externalReference?: string | null;
}
