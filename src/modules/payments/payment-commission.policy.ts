import { APP_COMMISSION_PERCENTAGE } from "@config/config";

/** Estados internos de liquidación al instructor (cuenta única; sin marketplace MP). */
export const InstructorPayoutStatus = {
  NOT_APPLICABLE: "not_applicable",
  PENDING_INTERNAL_PAYOUT: "pending_internal",
  ELIGIBLE_FOR_PAYOUT: "eligible",
  PAID_OUT: "paid_out",
} as const;

export type InstructorPayoutStatusValue =
  (typeof InstructorPayoutStatus)[keyof typeof InstructorPayoutStatus];

export interface PaymentCommissionSplit {
  grossAmount: number;
  /** Porcentaje que retiene la app sobre el bruto (ej. 20). */
  commissionRate: number;
  appCommission: number;
  instructorAmount: number;
}

function roundMoney(n: number): number {
  return Math.round(n * 100) / 100;
}

/**
 * Reparto bruto → comisión app + neto instructor.
 * Usa el % configurado en el instructor si viene definido; si no, `APP_COMMISSION_PERCENTAGE` del env.
 */
export function splitGrossByAppCommissionPercent(
  gross: number,
  instructorConfiguredAppPercent?: number | null
): PaymentCommissionSplit {
  const rate =
    instructorConfiguredAppPercent != null &&
    !Number.isNaN(Number(instructorConfiguredAppPercent))
      ? Number(instructorConfiguredAppPercent)
      : APP_COMMISSION_PERCENTAGE;
  const clamped = Math.min(100, Math.max(0, rate));
  const grossRounded = roundMoney(Number(gross));
  const appCommission = roundMoney(grossRounded * (clamped / 100));
  const instructorAmount = roundMoney(grossRounded - appCommission);
  return {
    grossAmount: grossRounded,
    commissionRate: clamped,
    appCommission,
    instructorAmount,
  };
}
