import { InstructorDocumentReviewStatus } from "@prisma/client";
import type { Instructor, InstructorDocumentReview } from "@prisma/client";

/** Tipos de documento obligatorios alineados con admin y Flutter. */
export const MANDATORY_DOCUMENT_TYPES = [
  "dobleComandoImg",
  "seguroImg",
  "vtvImg",
  "reincidenciaImg",
  "licenciaImg",
] as const;

export type MandatoryDocumentType = (typeof MANDATORY_DOCUMENT_TYPES)[number];

/** Claves estables para cliente (Flutter) y mensajes. */
export type PublishabilityReason =
  | "account_not_valid"
  | "not_listed"
  | "missing_profile_image"
  | "missing_bio"
  | "missing_hourly_rate"
  | "invalid_hourly_rate"
  | "missing_location"
  | "missing_experience"
  | "document_missing_file"
  | "document_not_approved"
  | "document_rejected"
  | "document_pending_review";

export type InstructorForPublishability = Pick<
  Instructor,
  | "isValid"
  | "isListed"
  | "experienceYears"
  | "bio"
  | "hourlyRate"
  | "lat"
  | "lng"
  | "dobleComandoImg"
  | "seguroImg"
  | "vtvImg"
  | "reincidenciaImg"
  | "licenciaImg"
> & {
  documentReviews?: Pick<InstructorDocumentReview, "documentType" | "status">[] | null;
};

/** Solo hace falta la foto de perfil del usuario vinculado. */
type UserForPublishability = { profileImage?: string | null } | null | undefined;

function filePresent(value: string | null | undefined): boolean {
  return value != null && String(value).trim().length > 0;
}

/**
 * Bloqueos de perfil + documentación (sin `isValid` ni `isListed`).
 * Sirve para auto-`isValid`, onboarding track 2 y validar listado sin depender del flag de cuenta.
 */
export function getInstructorVerificationBlockers(
  instructor: InstructorForPublishability,
  user: UserForPublishability
): PublishabilityReason[] {
  const reasons: PublishabilityReason[] = [];

  const img = user?.profileImage?.toString().trim();
  if (!img) {
    reasons.push("missing_profile_image");
  }

  const bio = instructor.bio?.toString().trim();
  if (!bio) {
    reasons.push("missing_bio");
  }

  const hr = instructor.hourlyRate;
  if (hr == null) {
    reasons.push("missing_hourly_rate");
  } else if (typeof hr === "number" && hr <= 0) {
    reasons.push("invalid_hourly_rate");
  }

  if (instructor.lat == null || instructor.lng == null) {
    reasons.push("missing_location");
  }

  const exp = instructor.experienceYears;
  if (exp == null || (typeof exp === "number" && exp < 0)) {
    reasons.push("missing_experience");
  }

  const byType = new Map<string, InstructorDocumentReviewStatus>();
  for (const r of instructor.documentReviews ?? []) {
    byType.set(r.documentType, r.status);
  }

  for (const docType of MANDATORY_DOCUMENT_TYPES) {
    const urlKey = docType as keyof InstructorForPublishability;
    const path = instructor[urlKey] as string | null | undefined;
    if (!filePresent(path)) {
      reasons.push("document_missing_file");
      continue;
    }
    const st = byType.get(docType);
    if (st === InstructorDocumentReviewStatus.REJECTED) {
      reasons.push("document_rejected");
    } else if (st === InstructorDocumentReviewStatus.PENDING_REVIEW) {
      reasons.push("document_pending_review");
    } else if (
      st === InstructorDocumentReviewStatus.MISSING ||
      st === undefined ||
      st !== InstructorDocumentReviewStatus.APPROVED
    ) {
      reasons.push("document_not_approved");
    }
  }

  return [...new Set(reasons)];
}

/** Razones que solo refieren al perfil profesional (sin documentación ni listado). */
const PROFESSIONAL_PROFILE_REASONS = new Set<PublishabilityReason>([
  "missing_profile_image",
  "missing_bio",
  "missing_hourly_rate",
  "invalid_hourly_rate",
  "missing_location",
  "missing_experience",
]);

/**
 * Bloqueos del perfil profesional solamente: foto, bio, tarifa, zona, experiencia.
 * No incluye documentación ni `isListed` (track separado de publicación).
 */
export function getProfessionalProfileFieldBlockers(
  instructor: InstructorForPublishability,
  user: UserForPublishability
): PublishabilityReason[] {
  return getInstructorVerificationBlockers(instructor, user).filter((r) =>
    PROFESSIONAL_PROFILE_REASONS.has(r)
  );
}

/** Track 2: perfil profesional completo (independiente de docs y de visibilidad). */
export function instructorProfessionalProfileComplete(
  instructor: InstructorForPublishability,
  user: UserForPublishability
): boolean {
  return getProfessionalProfileFieldBlockers(instructor, user).length === 0;
}

/** Criterio para marcar la cuenta como válida automáticamente (docs aprobados + perfil mínimo). */
export function instructorMeetsVerifiedAccountCriteria(
  instructor: InstructorForPublishability,
  user: UserForPublishability
): boolean {
  return getInstructorVerificationBlockers(instructor, user).length === 0;
}

/**
 * ¿Puede quedar `isListed=true` con los datos actuales? (equivale a publicable salvo `not_listed`).
 */
export function instructorMeetsPublicListingRequirements(
  instructor: InstructorForPublishability,
  user: UserForPublishability
): { ok: boolean; reasons: PublishabilityReason[] } {
  const merged: InstructorForPublishability = {
    ...instructor,
    isListed: true,
  };
  const { reasons } = evaluateInstructorPublishable(merged, user);
  const filtered = reasons.filter((r) => r !== "not_listed");
  return { ok: filtered.length === 0, reasons: filtered };
}

/**
 * Reglas: visible en búsqueda / perfil público solo si cuenta aprobada, listado activado,
 * perfil mínimo (foto, bio, precio, zona, experiencia) y los 5 documentos con review APPROVED (incl. licencia).
 */
export function evaluateInstructorPublishable(
  instructor: InstructorForPublishability,
  user: UserForPublishability
): { publishable: boolean; reasons: PublishabilityReason[] } {
  const reasons: PublishabilityReason[] = [];

  if (!instructor.isValid) {
    reasons.push("account_not_valid");
  }
  if (!instructor.isListed) {
    reasons.push("not_listed");
  }

  reasons.push(...getInstructorVerificationBlockers(instructor, user));

  const unique = [...new Set(reasons)];
  return { publishable: unique.length === 0, reasons: unique };
}
