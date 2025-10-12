export interface Payment {
  id: number;
  amount: number;
  status: string;
  paymentMethod: string;
  drivingClassId: number;
  // Mercado Pago specific fields
  preferenceId?: string | null;
  paymentId?: string | null;
  externalReference?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreatePaymentData {
  amount: number;
  paymentMethod: string;
  drivingClassId: number;
  // Optional Mercado Pago fields
  preferenceId?: string | null;
  paymentId?: string | null;
  externalReference?: string | null;
}

export interface UpdatePaymentData {
  status?: string;
  // Mercado Pago specific fields
  preferenceId?: string | null;
  paymentId?: string | null;
  externalReference?: string | null;
}