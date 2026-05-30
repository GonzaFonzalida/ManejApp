import { Request, Response } from "express";
import InstructorService from "./instructor.services";
import { ExpressFunction } from "@sharedTypes/ExpressFunction";
import CustomizedError from "@shared/classes/CustomizedError";
import { sanitizeInstructorMpFields } from "./instructor-mp.service";

export default class InstructorController {
  constructor(private instructorService: InstructorService) { }

  /**
   * GET /instructors/me — full profile for authenticated instructor.
   * Auth required, role INSTRUCTOR only (enforced in routes).
   */
  getMe: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      if (!userId) return next(new CustomizedError("No autenticado", 401));
      const profile = await this.instructorService.getProfileForMeResponse(userId);
      if (!profile) return next(new CustomizedError("Perfil de instructor no encontrado", 404));
      return res.json(sanitizeInstructorMpFields(profile as unknown as Record<string, unknown>));
    } catch (err) {
      next(err);
    }
  };

  /**
   * PUT /instructors/me — update own instructor profile.
   * Auth required, role INSTRUCTOR only.
   */
  updateMe: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      if (!userId) return next(new CustomizedError("No autenticado", 401));
      const updated = await this.instructorService.updateProfileByUserId(userId, req.body);
      if (!updated) return next(new CustomizedError("Perfil de instructor no encontrado", 404));
      const full = await this.instructorService.getProfileForMeResponse(userId);
      return res.json(sanitizeInstructorMpFields((full ?? updated) as unknown as Record<string, unknown>));
    } catch (err) {
      next(err);
    }
  };

  /**
   * PATCH /instructors/me/listed — set isListed (body: { isListed: boolean }).
   * Auth required, role INSTRUCTOR only.
   */
  patchListed: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      if (!userId) return next(new CustomizedError("No autenticado", 401));
      const result = await this.instructorService.setListed(userId, req.body.isListed);
      if (!result) return next(new CustomizedError("Perfil de instructor no encontrado", 404));
      return res.json(result);
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /instructors/me/documents
   * Upload an instructor document (base64)
   * Auth required, role INSTRUCTOR only.
   */
  uploadDocument: ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user?.id;
      if (!userId) return next(new CustomizedError("No autenticado", 401));

      const { documentType, image, mimeType } = req.body;
      const profile = await this.instructorService.getProfileByUserId(userId);
      if (!profile) return next(new CustomizedError("Perfil de instructor no encontrado", 404));

      const fileUrl = await this.instructorService.uploadDocumentBase64(
        profile.id,
        documentType,
        image,
        mimeType
      );

      return res.json({
        success: true,
        message: "Documento subido correctamente",
        data: {
          documentType,
          url: fileUrl
        }
      });
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /instructors/nearby — listed instructors near (lat,lng) within radiusKm, sorted by distance.
   * Public; query validated by nearbyQuerySchema (lat, lng required; radiusKm, limit optional).
   */
  getNearby: ExpressFunction = async (req, res, next) => {
    try {
      const query = (req as any).validatedQuery as { lat: number; lng: number; radiusKm: number; limit: number };
      const list = await this.instructorService.getNearby(query);
      return res.json(list);
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /instructors/:id — public profile (safe fields only).
   * Returns 404 if instructor not found or isListed=false.
   */
  getPublicProfile: ExpressFunction = async (req, res, next) => {
    try {
      const id = Number(req.params.id);
      if (!Number.isInteger(id) || id < 1) return next(new CustomizedError("ID de instructor inválido", 422));
      const profile = await this.instructorService.getPublicProfile(id);
      if (!profile) return next(new CustomizedError("Instructor no encontrado o no disponible", 404));
      return res.json(profile);
    } catch (err) {
      next(err);
    }
  };

  register: ExpressFunction = async (req, res, next) => {
    try {
      const instructor = await this.instructorService.registerInstructor(req.body);
      res.status(201).json(instructor);
    } catch (err) {
      next(err);
    }
  };

  /**
   * PUT /instructors/:id — update by id; only allowed for own profile (auth required, id must match authenticated instructor).
   */
  updateProfile: ExpressFunction = async (req, res, next) => {
    try {
      const instructorId = Number(req.params.id);
      const userId = (req as any).user?.id;
      if (!Number.isInteger(instructorId) || instructorId < 1) {
        return next(new CustomizedError("ID de instructor inválido", 422));
      }
      if (!userId) {
        return next(new CustomizedError("No autenticado", 401));
      }
      const instructor = await this.instructorService.getProfileByUserId(userId);
      if (!instructor || (instructor as any).id !== instructorId) {
        return next(new CustomizedError("No autorizado a editar este perfil", 403));
      }
      const updatedInstructor = await this.instructorService.updateInstructor(instructorId, req.body);
      if (!updatedInstructor) {
        return next(new CustomizedError("Instructor no encontrado", 404));
      }
      const full = await this.instructorService.getInstructorProfile(instructorId);
      return res.json(full ?? updatedInstructor);
    } catch (err) {
      next(err);
    }
  };

  /**
   * GET /instructors/:id — legacy handler; now delegates to public profile (same contract: 404 if not listed).
   */
  getProfile: ExpressFunction = async (req, res, next) => {
    return this.getPublicProfile(req, res, next);
  };

  list: ExpressFunction = async (req, res, next) => {
    try {
      const { minPrice, maxPrice, transmission, hasAvailability } = req.query;
      const filter: any = {};
      if (minPrice != null) filter.minPrice = Number(minPrice);
      if (maxPrice != null) filter.maxPrice = Number(maxPrice);
      if (transmission === "MANUAL" || transmission === "AUTOMATIC") filter.transmission = transmission;
      if (hasAvailability === "true" || hasAvailability === "1") filter.hasAvailability = true;
      const instructors = await this.instructorService.listInstructors(Object.keys(filter).length > 0 ? filter : undefined);
      res.json(instructors);
    } catch (err) {
      next(err);
    }
  };
}
