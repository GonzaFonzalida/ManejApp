import { InstructorDocumentReviewStatus } from "@prisma/client";
import {
  evaluateInstructorPublishable,
  getProfessionalProfileFieldBlockers,
  instructorProfessionalProfileComplete,
  MANDATORY_DOCUMENT_TYPES,
  type InstructorForPublishability,
} from "../../src/modules/instructors/instructorPublishable";

function approvedReviews(): { documentType: string; status: InstructorDocumentReviewStatus }[] {
  return MANDATORY_DOCUMENT_TYPES.map((documentType) => ({
    documentType,
    status: InstructorDocumentReviewStatus.APPROVED,
  }));
}

function baseInstructor(overrides: Partial<InstructorForPublishability> = {}): InstructorForPublishability {
  return {
    isValid: true,
    isListed: true,
    experienceYears: 3,
    bio: "Descripción profesional",
    hourlyRate: 15000,
    lat: -34.6,
    lng: -58.4,
    dobleComandoImg: "/d1",
    seguroImg: "/d2",
    vtvImg: "/d3",
    reincidenciaImg: "/d4",
    licenciaImg: "/d5",
    documentReviews: approvedReviews(),
    ...overrides,
  };
}

describe("evaluateInstructorPublishable", () => {
  it("is publishable when all rules pass", () => {
    const r = evaluateInstructorPublishable(baseInstructor(), { profileImage: "/face.jpg" });
    expect(r.publishable).toBe(true);
    expect(r.reasons).toEqual([]);
  });

  it("fails when account not valid", () => {
    const r = evaluateInstructorPublishable(baseInstructor({ isValid: false }), { profileImage: "/p" });
    expect(r.publishable).toBe(false);
    expect(r.reasons).toContain("account_not_valid");
  });

  it("fails when not listed", () => {
    const r = evaluateInstructorPublishable(baseInstructor({ isListed: false }), { profileImage: "/p" });
    expect(r.reasons).toContain("not_listed");
  });

  it("fails when profile image missing", () => {
    const r = evaluateInstructorPublishable(baseInstructor(), { profileImage: null });
    expect(r.reasons).toContain("missing_profile_image");
  });

  it("fails when document was rejected", () => {
    const reviews = approvedReviews();
    reviews[0] = { ...reviews[0], status: InstructorDocumentReviewStatus.REJECTED };
    const r = evaluateInstructorPublishable(baseInstructor({ documentReviews: reviews }), {
      profileImage: "/p",
    });
    expect(r.reasons).toContain("document_rejected");
  });

  it("fails when document pending review after re-upload", () => {
    const reviews = approvedReviews();
    reviews[2] = { ...reviews[2], status: InstructorDocumentReviewStatus.PENDING_REVIEW };
    const r = evaluateInstructorPublishable(baseInstructor({ documentReviews: reviews }), {
      profileImage: "/p",
    });
    expect(r.reasons).toContain("document_pending_review");
  });
});

describe("getProfessionalProfileFieldBlockers / instructorProfessionalProfileComplete", () => {
  it("ignora bloqueos de documentación", () => {
    const reviews = approvedReviews();
    reviews[0] = { ...reviews[0], status: InstructorDocumentReviewStatus.PENDING_REVIEW };
    const inst = baseInstructor({ documentReviews: reviews });
    const prof = getProfessionalProfileFieldBlockers(inst, { profileImage: "/p" });
    expect(prof).toEqual([]);
    expect(instructorProfessionalProfileComplete(inst, { profileImage: "/p" })).toBe(true);
  });

  it("detecta bio faltante aunque docs estén aprobados", () => {
    const inst = baseInstructor({ bio: "" });
    const prof = getProfessionalProfileFieldBlockers(inst, { profileImage: "/p" });
    expect(prof).toContain("missing_bio");
    expect(instructorProfessionalProfileComplete(inst, { profileImage: "/p" })).toBe(false);
  });
});
