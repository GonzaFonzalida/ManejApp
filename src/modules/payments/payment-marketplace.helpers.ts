import { Payment } from "./payment.types";

/** Preferencia marketplace válida y reutilizable (Fase 2). */
export function isMarketplacePreferenceReady(payment: Pick<Payment, "mpCollectorId" | "marketplaceFee" | "preferenceInitPoint">): boolean {
  return (
    payment.mpCollectorId != null &&
    payment.mpCollectorId.trim() !== "" &&
    payment.marketplaceFee != null &&
    payment.marketplaceFee > 0 &&
    Boolean(payment.preferenceInitPoint)
  );
}

/** Preferencia creada antes de Fase 2 (cuenta plataforma, sin split). */
export function isLegacyPlatformPreference(
  payment: Pick<Payment, "preferenceId" | "mpCollectorId" | "marketplaceFee">
): boolean {
  return Boolean(payment.preferenceId) && !isMarketplacePreferenceReady(payment);
}

/** Reutilizar solo si marketplace coincide con collector y fee actuales. */
export function canReuseMarketplacePreference(
  payment: Pick<
    Payment,
    "preferenceId" | "mpCollectorId" | "marketplaceFee" | "preferenceInitPoint"
  >,
  mpCollectorId: string,
  marketplaceFee: number
): boolean {
  return (
    Boolean(payment.preferenceId) &&
    isMarketplacePreferenceReady(payment) &&
    payment.mpCollectorId === mpCollectorId &&
    payment.marketplaceFee === marketplaceFee
  );
}

/** external_reference de MP debe coincidir con la reserva local. */
export function mpExternalReferenceMatchesBooking(
  mpExternalRef: unknown,
  bookingId: number,
  localExternalReference?: string | null
): boolean {
  const parsed = mpExternalRef != null ? parseInt(String(mpExternalRef), 10) : NaN;
  if (!Number.isInteger(parsed) || parsed !== bookingId) return false;
  if (localExternalReference != null && localExternalReference !== String(bookingId)) {
    return false;
  }
  return true;
}

/** Monto MP vs DB dentro de tolerancia (ARS). */
export function mpAmountMatchesDb(mpAmount: number | null, dbAmount: number, tolerance = 0.02): boolean {
  if (mpAmount == null) return true;
  return Math.abs(mpAmount - dbAmount) <= tolerance;
}
