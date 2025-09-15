import { Payment } from "../payment.types";

export interface PaymentRepository {
  createPayment(data: {
    amount: number;
    paymentMethod: string;
    drivingClassId: number;
    preferenceId?: string | null;
    paymentId?: string | null;
    externalReference?: string | null;
  }): Promise<Payment>;

  getPaymentById(id: number): Promise<Payment | null>;

  getPaymentsByDrivingClass(drivingClassId: number): Promise<Payment[]>;

  updatePaymentStatus(id: number, status: string): Promise<Payment>;

  listPayments(filter?: { status?: string }): Promise<Payment[]>;

  // Mercado Pago specific methods
  updatePaymentWithMercadoPagoData(id: number, data: {
    preferenceId?: string | null;
    paymentId?: string | null;
    externalReference?: string | null;
    status?: string;
  }): Promise<Payment>;

  getPaymentByExternalReference(externalReference: string): Promise<Payment | null>;

  getPaymentByPreferenceId(preferenceId: string): Promise<Payment | null>;

  getPaymentByPaymentId(paymentId: string): Promise<Payment | null>;
}