import { BookingStatus as PrismaBookingStatus } from "@prisma/client";

/**
 * Re-export Prisma enum as the single source of truth (type + runtime values).
 */
export { PrismaBookingStatus as BookingStatus };

/**
 * Statuses that represent an "active" booking (not yet completed or cancelled).
 * Used for counts and filters (e.g. "scheduled" / "active" classes).
 */
export const ACTIVE_STATUSES: readonly PrismaBookingStatus[] = [
  PrismaBookingStatus.PENDING_PAYMENT,
  PrismaBookingStatus.CONFIRMED,
] as const;

/**
 * Returns true if the status is one of ACTIVE_STATUSES.
 */
export function isActiveBookingStatus(status: string): boolean {
  return (ACTIVE_STATUSES as readonly string[]).includes(status);
}

/**
 * Returns true if the status is CONFIRMED (booking confirmed, not just pending payment).
 */
export function isConfirmedStatus(status: string): boolean {
  return status === PrismaBookingStatus.CONFIRMED;
}

/**
 * Legacy string values that may still appear in inputs or DB during migration.
 */
const LEGACY_TO_STATUS: Record<string, PrismaBookingStatus> = {
  scheduled: PrismaBookingStatus.CONFIRMED,
  completed: PrismaBookingStatus.COMPLETED,
  cancelled: PrismaBookingStatus.CANCELLED,
  canceled: PrismaBookingStatus.CANCELLED,
};

const VALID_STATUSES = new Set<string>(Object.values(PrismaBookingStatus));

/**
 * Normalizes a string to a BookingStatus enum value.
 * Handles legacy strings (scheduled, completed, cancelled, canceled).
 * Returns null if input is not a valid or legacy status.
 */
export function normalizeBookingStatus(input: string | null | undefined): PrismaBookingStatus | null {
  if (input == null || input === "") return null;
  const normalized = input.trim();
  const legacy = LEGACY_TO_STATUS[normalized.toLowerCase()];
  if (legacy) return legacy;
  return VALID_STATUSES.has(normalized) ? (normalized as PrismaBookingStatus) : null;
}
