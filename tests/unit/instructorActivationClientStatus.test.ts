import { InstructorDocumentReviewStatus } from "@prisma/client";
import {
  buildInstructorOnboardingPayload,
  computeActivationClientStatusFromParts,
  getInstructorActivationClientStatus,
} from "../../src/modules/instructors/instructorOnboardingDto";
import type { InstructorForPublishability } from "../../src/modules/instructors/instructorPublishable";

describe("activationClientStatus (instructor onboarding)", () => {
  it("no es active con documentos en pending_review aunque perfil completo", () => {
    const instructor = {
      isValid: true,
      isListed: false,
      experienceYears: 3,
      bio: "Bio",
      hourlyRate: 5000,
      lat: -34.6,
      lng: -58.4,
      dobleComandoImg: "/d.png",
      seguroImg: "/s.png",
      vtvImg: "/v.png",
      reincidenciaImg: "/r.png",
      licenciaImg: "/l.png",
      documentReviews: [
        { documentType: "dobleComandoImg", status: InstructorDocumentReviewStatus.APPROVED },
        { documentType: "seguroImg", status: InstructorDocumentReviewStatus.APPROVED },
        { documentType: "vtvImg", status: InstructorDocumentReviewStatus.PENDING_REVIEW },
        { documentType: "reincidenciaImg", status: InstructorDocumentReviewStatus.APPROVED },
        { documentType: "licenciaImg", status: InstructorDocumentReviewStatus.APPROVED },
      ],
    } as unknown as InstructorForPublishability & {
      documentReviews: { documentType: string; status: InstructorDocumentReviewStatus }[];
    };
    const user = { profileImage: "/p.jpg" };
    const st = getInstructorActivationClientStatus(instructor, user);
    expect(st).toBe("documents_pending");
    const onboarding = buildInstructorOnboardingPayload(instructor, user);
    expect(onboarding.activationTrack.clientStatus).toBe("documents_pending");
  });

  it("no es active con documento rechazado", () => {
    const st = computeActivationClientStatusFromParts(
      false,
      "rejected",
      "complete",
      true,
      false,
      true
    );
    expect(st).toBe("documents_rejected");
  });

  it("active solo cuando publishable es true (docs+perfil+cuenta+listado)", () => {
    expect(computeActivationClientStatusFromParts(true, "complete", "complete", true, true, true)).toBe(
      "active"
    );
    expect(
      computeActivationClientStatusFromParts(false, "complete", "complete", true, false, true)
    ).toBe("awaiting_visibility");
    expect(
      computeActivationClientStatusFromParts(false, "complete", "complete", true, true, false)
    ).toBe("blocked");
  });

  it("profile_incomplete cuando documentos listos pero falta perfil", () => {
    expect(
      computeActivationClientStatusFromParts(false, "complete", "incomplete", true, false, false)
    ).toBe("profile_incomplete");
  });

  it("awaiting_visibility cuando docs y perfil profesional listos pero falta listar", () => {
    const instructor = {
      isValid: true,
      isListed: false,
      experienceYears: 3,
      bio: "Bio",
      hourlyRate: 5000,
      lat: -34.6,
      lng: -58.4,
      dobleComandoImg: "/d.png",
      seguroImg: "/s.png",
      vtvImg: "/v.png",
      reincidenciaImg: "/r.png",
      licenciaImg: "/l.png",
      documentReviews: [
        { documentType: "dobleComandoImg", status: InstructorDocumentReviewStatus.APPROVED },
        { documentType: "seguroImg", status: InstructorDocumentReviewStatus.APPROVED },
        { documentType: "vtvImg", status: InstructorDocumentReviewStatus.APPROVED },
        { documentType: "reincidenciaImg", status: InstructorDocumentReviewStatus.APPROVED },
        { documentType: "licenciaImg", status: InstructorDocumentReviewStatus.APPROVED },
      ],
    } as unknown as InstructorForPublishability & {
      documentReviews: { documentType: string; status: InstructorDocumentReviewStatus }[];
    };
    const user = { profileImage: "/p.jpg" };
    expect(getInstructorActivationClientStatus(instructor, user)).toBe("awaiting_visibility");
    const onboarding = buildInstructorOnboardingPayload(instructor, user);
    expect(onboarding.profileTrack.summary).toBe("complete");
    expect(onboarding.profileTrack.items.some((i) => i.id === "visibility")).toBe(false);
    expect(onboarding.activationTrack.listing.isListed).toBe(false);
    expect(onboarding.activationTrack.listing.canEnablePublicListing).toBe(true);
    expect(onboarding.activationTrack.listing.reasonsBlockingListing).toEqual([]);
  });
});
