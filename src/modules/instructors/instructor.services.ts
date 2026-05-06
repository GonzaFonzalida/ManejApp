import { InstructorRepository } from "./repositories/InstructorRepository";
import { Instructor } from "@prisma/client";
import CustomizedError from "@shared/classes/CustomizedError";
import {
  evaluateInstructorPublishable,
  type InstructorForPublishability,
} from "./instructorPublishable";
import { buildInstructorOnboardingPayload } from "./instructorOnboardingDto";
import { syncInstructorAutoValidity } from "./instructorValiditySync";

/** Perfil tal como lo devuelve Prisma con `include: { user, documentReviews }`. */
type InstructorWithUserAndReviews = Instructor & {
  user: { profileImage?: string | null; name?: string; surname?: string } | null;
  documentReviews?: { documentType: string; status: import("@prisma/client").InstructorDocumentReviewStatus }[];
};
import { PermissionRepository } from "../permissions/repositories/IPermissionsRepository";
import { UserRepository } from "@users/repositories/userRepository";
import path from "path";
import fs from "fs";

/** Earth radius in km for Haversine formula. */
const EARTH_RADIUS_KM = 6371;

function haversineDistanceKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_KM * c;
}

export default class InstructorService {
  constructor(
    private instructorRepo: InstructorRepository,
    private userRepo: UserRepository,
    private permissionRepo: PermissionRepository,
  ) { }

  async registerInstructor(data: {
    userId: number;
    licenseNumber?: string | null;
    experienceYears: number;
    carId?: number;
    hourlyRate?: number;
  }) {
    // 1. Verificar que exista el usuario
    const user = await this.userRepo.findUser(String(data.userId));
    if (!user) throw new CustomizedError("Usuario no encontrado", 404);

    if (user.role !== "STUDENT") {
      throw new Error("El usuario no puede registrarse como instructor");
    }

    const existingInstructor = await this.instructorRepo.getInstructorByUserId(data.userId);
    if (existingInstructor) {
      throw new CustomizedError("Este usuario ya es instructor", 409);
    }

    // 3. Crear el instructor
    const instructor = await this.instructorRepo.createInstructor(data);

    // 4. Cambiar el role del usuario a INSTRUCTOR
    await this.userRepo.updateRole(data.userId, "INSTRUCTOR");

    // 5. Obtener todos los permisos de la tabla Permission
    const permissions = await this.permissionRepo.findAll();

    // 5. Crear los registros en InstructorPermission
    for (const permission of permissions) {
      await this.instructorRepo.addPermission(
        instructor.id,
        permission.id
      );
    }

    return instructor;
  }

  async getInstructorProfile(id: number) {
    return this.instructorRepo.getInstructorById(id);
  }

  /** Full profile for the authenticated instructor (by user id). */
  async getProfileByUserId(userId: number) {
    return this.instructorRepo.getInstructorProfileByUserId(userId);
  }

  /**
   * Perfil /me con flags de publicación (misma fuente de verdad que búsqueda y PATCH listed).
   */
  async getProfileForMeResponse(userId: number) {
    const profile = (await this.getProfileByUserId(userId)) as InstructorWithUserAndReviews | null;
    if (!profile) return null;
    const { publishable, reasons } = evaluateInstructorPublishable(
      profile as unknown as InstructorForPublishability,
      profile.user
    );
    const onboarding = buildInstructorOnboardingPayload(
      profile as InstructorForPublishability & {
        documentReviews?: Array<{
          documentType: string;
          status: import("@prisma/client").InstructorDocumentReviewStatus;
          rejectionReason?: string | null;
        }>;
      },
      profile.user
    );
    const activationClientStatus = onboarding.activationTrack.clientStatus;
    return {
      ...profile,
      publishable,
      publishBlockedReasons: reasons,
      onboarding,
      activationClientStatus,
    };
  }

  /** Update instructor profile; caller must ensure userId owns the instructor. */
  async updateProfileByUserId(userId: number, data: Partial<Instructor>): Promise<Instructor | null> {
    const instructor = await this.instructorRepo.getInstructorByUserId(userId);
    if (!instructor) return null;
    const fullBefore = (await this.instructorRepo.getInstructorProfileByUserId(
      userId
    )) as InstructorWithUserAndReviews | null;
    if (!fullBefore) return null;

    if (data.isListed === true) {
      const merged = { ...fullBefore, ...data } as InstructorWithUserAndReviews;
      const { publishable, reasons } = evaluateInstructorPublishable(
        merged as unknown as InstructorForPublishability,
        merged.user ?? fullBefore.user
      );
      if (!publishable) {
        throw new CustomizedError(
          "No cumplís los requisitos para aparecer en búsquedas",
          422,
          { missing: reasons }
        );
      }
    }

    const updated = await this.instructorRepo.updateInstructor(instructor.id, data);
    const full = (await this.instructorRepo.getInstructorProfileByUserId(
      userId
    )) as InstructorWithUserAndReviews | null;
    if (full?.isListed) {
      const { publishable } = evaluateInstructorPublishable(
        full as unknown as InstructorForPublishability,
        full.user
      );
      if (!publishable) {
        await this.instructorRepo.updateInstructor(full.id, { isListed: false });
      }
    }
    await syncInstructorAutoValidity(instructor.id);
    return updated;
  }

  /** Set isListed for the instructor identified by userId. */
  async setListed(userId: number, isListed: boolean): Promise<{ isListed: boolean } | null> {
    const instructor = await this.instructorRepo.getInstructorByUserId(userId);
    if (!instructor) return null;
    if (isListed) {
      const full = (await this.instructorRepo.getInstructorProfileByUserId(
        userId
      )) as InstructorWithUserAndReviews | null;
      if (!full?.user) return null;
      const { publishable, reasons } = evaluateInstructorPublishable(
        full as unknown as InstructorForPublishability,
        full.user
      );
      if (!publishable) {
        throw new CustomizedError(
          "No cumplís los requisitos para aparecer en búsquedas",
          422,
          { missing: reasons }
        );
      }
    }
    await this.instructorRepo.updateInstructor(instructor.id, { isListed });
    await syncInstructorAutoValidity(instructor.id);
    return { isListed };
  }

  /**
   * Nearby instructors: isListed=true, lat/lng not null, within radiusKm of (lat,lng).
   * Bounding box + Haversine filter; sorted by distance ascending; limited.
   */
  async getNearby(params: { lat: number; lng: number; radiusKm: number; limit: number }): Promise<NearbyInstructorItem[]> {
    const { lat, lng, radiusKm, limit } = params;
    const degLatKm = 111;
    const degLngKm = 111 * Math.max(0.01, Math.cos((lat * Math.PI) / 180));
    const latDelta = radiusKm / degLatKm;
    const lngDelta = radiusKm / degLngKm;
    const latMin = lat - latDelta;
    const latMax = lat + latDelta;
    const lngMin = lng - lngDelta;
    const lngMax = lng + lngDelta;
    const rows = await this.instructorRepo.findListedInBounds(latMin, latMax, lngMin, lngMax);
    const withDistance = rows
      .filter((r) => r.lat != null && r.lng != null)
      .map((r) => {
        const distanceKm = haversineDistanceKm(lat, lng, r.lat!, r.lng!);
        return { row: r, distanceKm };
      })
      .filter((x) => x.distanceKm <= radiusKm)
      .filter((x) => {
        const row = x.row as InstructorWithUserAndReviews;
        const { publishable } = evaluateInstructorPublishable(
          row as unknown as InstructorForPublishability,
          row.user
        );
        return publishable;
      })
      .sort((a, b) => a.distanceKm - b.distanceKm)
      .slice(0, limit);
    return withDistance.map(({ row, distanceKm }) => {
      const u = row.user;
      const displayName = u ? [u.name, u.surname].filter(Boolean).join(" ").trim() || "Instructor" : "Instructor";
      const categories = row.categories != null && Array.isArray(row.categories) ? (row.categories as string[]) : null;
      const photos = row.photos != null && Array.isArray(row.photos) ? (row.photos as string[]) : null;
      return {
        id: row.id,
        displayName,
        bio: row.bio ?? null,
        categories,
        photos,
        hourlyRate: row.hourlyRate ?? null,
        lat: row.lat!,
        lng: row.lng!,
        distanceKm: Math.round(distanceKm * 100) / 100,
      };
    });
  }

  /**
   * Public profile by instructor id. Returns only public-safe fields.
   * Returns null if instructor not found or isListed is false (not visible in listing).
   */
  async getPublicProfile(id: number): Promise<PublicInstructorProfile | null> {
    const row = (await this.instructorRepo.getInstructorById(id)) as InstructorWithUserAndReviews | null;
    if (!row || !row.isListed) return null;
    const { publishable } = evaluateInstructorPublishable(
      row as unknown as InstructorForPublishability,
      row.user
    );
    if (!publishable) return null;
    const withUser = row as Instructor & { user?: { name?: string; surname?: string } };
    const displayName = withUser.user
      ? [withUser.user.name, withUser.user.surname].filter(Boolean).join(" ").trim() || "Instructor"
      : "Instructor";
    const categories = withUser.categories != null && Array.isArray(withUser.categories)
      ? (withUser.categories as string[])
      : null;
    const photos = withUser.photos != null && Array.isArray(withUser.photos)
      ? (withUser.photos as string[])
      : null;
    return {
      id: row.id,
      displayName,
      bio: row.bio ?? null,
      categories,
      photos,
      hourlyRate: row.hourlyRate ?? null,
      isListed: row.isListed,
      lat: row.lat ?? null,
      lng: row.lng ?? null,
    };
  }

  async listInstructors(filter?: {
    available?: boolean;
    isValid?: boolean;
    minPrice?: number;
    maxPrice?: number;
    transmission?: "MANUAL" | "AUTOMATIC";
    hasAvailability?: boolean;
  }) {
    return this.instructorRepo.listInstructors(filter);
  }

  async updateInstructor(
    id: number,
    data: Partial<Instructor>
  ): Promise<Instructor | null> {
    return this.instructorRepo.updateInstructor(id, data);
  }

  async uploadDocumentBase64(
    instructorId: number,
    documentType: string,
    image: string,
    mimeType?: string
  ) {
    // Determine extension
    let ext = ".jpg";
    if (mimeType) {
      if (mimeType.includes("png")) ext = ".png";
      else if (mimeType.includes("webp")) ext = ".webp";
      else if (mimeType.includes("pdf")) ext = ".pdf";
      else if (mimeType.includes("gif")) ext = ".gif";
    }

    // Parse base64
    const matches = image.match(/^data:([A-Za-z-+/]+);base64,(.+)$/);
    let buffer: Buffer;
    if (matches && matches.length === 3) {
      buffer = Buffer.from(matches[2], "base64");
    } else {
      buffer = Buffer.from(image, "base64");
    }

    // Save folder
    const uploadDir = path.join(process.cwd(), "uploads", "instructors_docs");
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const filename = `${documentType}-${instructorId}-${uniqueSuffix}${ext}`;
    const filepath = path.join(uploadDir, filename);

    fs.writeFileSync(filepath, buffer);

    const relativePath = `/api/v1/instructors/documents/${filename}`;

    // Save cleanly to DB
    await this.instructorRepo.updateDocument(instructorId, documentType, relativePath);
    await this.instructorRepo.upsertDocumentReviewPending(instructorId, documentType);
    await syncInstructorAutoValidity(instructorId);

    return relativePath;
  }

  async addPermission(instructorId: number, permissionId: number) {
    return this.instructorRepo.addPermission(instructorId, permissionId);
  }

  async validateIfHasAllPermissions(instructorId: number) {
    const hasAll = await this.instructorRepo.hasAllMandatoryPermissions(instructorId);
    if (hasAll) {
      return this.instructorRepo.validateInstructor(instructorId);
    }
    throw new CustomizedError("Instructor does not have all mandatory permissions", 400);
  }
}

/** Public-safe fields for GET /instructors/:id (no email, no internal ids beyond instructor id). */
export interface PublicInstructorProfile {
  id: number;
  displayName: string;
  bio: string | null;
  categories: string[] | null;
  photos: string[] | null;
  hourlyRate: number | null;
  isListed: boolean;
  lat: number | null;
  lng: number | null;
}

/** Item for GET /instructors/nearby (card + distance). */
export interface NearbyInstructorItem {
  id: number;
  displayName: string;
  bio: string | null;
  categories: string[] | null;
  photos: string[] | null;
  hourlyRate: number | null;
  lat: number;
  lng: number;
  distanceKm: number;
}
