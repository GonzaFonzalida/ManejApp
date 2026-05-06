import { InstructorDocumentReviewStatus } from "@prisma/client";
import {
  evaluateInstructorPublishable,
  instructorMeetsPublicListingRequirements,
  instructorProfessionalProfileComplete,
  MANDATORY_DOCUMENT_TYPES,
  type InstructorForPublishability,
  type PublishabilityReason,
} from "./instructorPublishable";

export type DocTrackItemStatus =
  | "missing"
  | "uploaded"
  | "pending_review"
  | "approved"
  | "rejected";

export type DocumentTrackSummary = "pending_review" | "rejected" | "complete";

export type ProfileTrackSummary = "incomplete" | "complete";

export type ActivationTrackSummary = "blocked" | "ready_to_list" | "listed";

/** Estado de producto para cliente: una sola fuente de verdad para UI y celebración. */
export type InstructorActivationClientStatus =
  | "active"
  | "documents_rejected"
  | "documents_pending"
  | "profile_incomplete"
  | "account_pending"
  | "awaiting_visibility"
  | "blocked";

export interface OnboardingDocumentItem {
  documentType: string;
  status: DocTrackItemStatus;
  rejectionReason?: string | null;
}

export interface OnboardingProfileItem {
  id: string;
  done: boolean;
}

/** Track 3: visibilidad / publicación (separado del perfil profesional). */
export interface OnboardingListingPayload {
  isListed: boolean;
  canEnablePublicListing: boolean;
  /** Por qué aún no se puede activar el listado público (sin incluir `not_listed`). */
  reasonsBlockingListing: PublishabilityReason[];
}

export interface InstructorOnboardingPayload {
  documentTrack: {
    summary: DocumentTrackSummary;
    items: OnboardingDocumentItem[];
  };
  profileTrack: {
    summary: ProfileTrackSummary;
    items: OnboardingProfileItem[];
  };
  activationTrack: {
    summary: ActivationTrackSummary;
    /** Motivos de publicación bloqueada (mismos códigos que publishBlockedReasons). */
    blockedReasons: PublishabilityReason[];
    /** Estado explícito para la app (no inferir solo con publishable parcial). */
    clientStatus: InstructorActivationClientStatus;
    /** Listado público: misma fuente que `canActivatePublicListing` en admin. */
    listing: OnboardingListingPayload;
  };
}

function filePresent(value: string | null | undefined): boolean {
  return value != null && String(value).trim().length > 0;
}

function docItemStatus(
  hasFile: boolean,
  reviewStatus: InstructorDocumentReviewStatus | undefined
): DocTrackItemStatus {
  if (!hasFile) return "missing";
  if (reviewStatus === InstructorDocumentReviewStatus.REJECTED) return "rejected";
  if (reviewStatus === InstructorDocumentReviewStatus.APPROVED) return "approved";
  if (reviewStatus === InstructorDocumentReviewStatus.PENDING_REVIEW) return "pending_review";
  if (hasFile) return "uploaded";
  return "missing";
}

type ReviewRow = {
  documentType: string;
  status: InstructorDocumentReviewStatus;
  rejectionReason?: string | null;
};

export function buildInstructorOnboardingPayload(
  instructor: InstructorForPublishability & { documentReviews?: ReviewRow[] | null },
  user: { profileImage?: string | null } | null | undefined
): InstructorOnboardingPayload {
  const byType = new Map<string, InstructorDocumentReviewStatus>();
  for (const r of instructor.documentReviews ?? []) {
    byType.set(r.documentType, r.status);
  }

  const docItems: OnboardingDocumentItem[] = MANDATORY_DOCUMENT_TYPES.map((docType) => {
    const urlKey = docType as keyof InstructorForPublishability;
    const path = instructor[urlKey] as string | null | undefined;
    const hasFile = filePresent(path);
    const st = byType.get(docType);
    const reviews = instructor.documentReviews as ReviewRow[] | undefined;
    const rejection = reviews?.find(
      (x) => x.documentType === docType && x.status === InstructorDocumentReviewStatus.REJECTED
    );
    return {
      documentType: docType,
      status: docItemStatus(hasFile, st),
      rejectionReason: rejection?.rejectionReason ?? null,
    };
  });

  let docSummary: DocumentTrackSummary = "complete";
  if (docItems.some((d) => d.status === "rejected")) docSummary = "rejected";
  else if (!docItems.every((d) => d.status === "approved")) docSummary = "pending_review";

  const img = user?.profileImage?.toString().trim();
  const hasPhoto = !!img;
  const bioOk = !!instructor.bio?.toString().trim();
  const hr = instructor.hourlyRate;
  const hourlyOk = hr != null && typeof hr === "number" && hr > 0;
  const zoneOk = instructor.lat != null && instructor.lng != null;
  const exp = instructor.experienceYears;
  const expOk = exp != null && !(typeof exp === "number" && exp < 0);

  /** Track 2 solo profesional (sin visibilidad / isListed — eso va en activationTrack.listing). */
  const profileItems: OnboardingProfileItem[] = [
    { id: "experience_years", done: expOk },
    { id: "profile_photo", done: hasPhoto },
    { id: "bio", done: bioOk },
    { id: "service_zone", done: zoneOk },
    { id: "hourly_rate", done: hourlyOk },
  ];

  const profileSummary: ProfileTrackSummary = instructorProfessionalProfileComplete(
    instructor,
    user
  )
    ? "complete"
    : "incomplete";

  const { publishable, reasons } = evaluateInstructorPublishable(instructor, user);
  const { ok: canListPublicly, reasons: listingPrepReasons } =
    instructorMeetsPublicListingRequirements(instructor, user);

  let activationSummary: ActivationTrackSummary = "blocked";
  if (instructor.isListed && publishable) activationSummary = "listed";
  else if (canListPublicly) activationSummary = "ready_to_list";
  else activationSummary = "blocked";

  const activationBlockedReasons: PublishabilityReason[] =
    activationSummary === "listed"
      ? []
      : activationSummary === "ready_to_list"
        ? (["not_listed"] as PublishabilityReason[])
        : [...new Set([...reasons, ...listingPrepReasons])];

  const clientStatus = computeActivationClientStatusFromParts(
    publishable,
    docSummary,
    profileSummary,
    instructor.isValid,
    instructor.isListed,
    canListPublicly
  );

  const listingPayload: OnboardingListingPayload = {
    isListed: instructor.isListed === true,
    canEnablePublicListing: canListPublicly,
    reasonsBlockingListing: [...listingPrepReasons],
  };

  return {
    documentTrack: { summary: docSummary, items: docItems },
    profileTrack: { summary: profileSummary, items: profileItems },
    activationTrack: {
      summary: activationSummary,
      blockedReasons: activationBlockedReasons,
      clientStatus,
      listing: listingPayload,
    },
  };
}

/** Deriva el estado de activación visible sin recalcular todo el payload. */
export function computeActivationClientStatusFromParts(
  publishable: boolean,
  documentSummary: DocumentTrackSummary,
  profileSummary: ProfileTrackSummary,
  isValid: boolean,
  isListed: boolean,
  canActivatePublicListing: boolean
): InstructorActivationClientStatus {
  if (publishable) return "active";
  if (documentSummary === "rejected") return "documents_rejected";
  if (documentSummary !== "complete") return "documents_pending";
  if (profileSummary !== "complete") return "profile_incomplete";
  if (!isValid) return "account_pending";
  if (canActivatePublicListing && !isListed) return "awaiting_visibility";
  return "blocked";
}

/**
 * Estado de activación para API /me (misma lógica que onboarding.activationTrack.clientStatus).
 */
export function getInstructorActivationClientStatus(
  instructor: InstructorForPublishability & { documentReviews?: ReviewRow[] | null },
  user: { profileImage?: string | null } | null | undefined
): InstructorActivationClientStatus {
  return buildInstructorOnboardingPayload(instructor, user).activationTrack.clientStatus;
}
