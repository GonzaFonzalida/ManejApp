import { Instructor } from "@prisma/client";

export interface InstructorRepository {
  createInstructor(data: {
    userId: number;
    licenseNumber?: string | null;
    experienceYears: number;
    hourlyRate?: number;
  }): Promise<Instructor>;
  getInstructorByUserId(userId: number): Promise<Instructor | null>;
  getInstructorById(id: number): Promise<Instructor | null>;
  /** Full profile by userId (same shape as getInstructorById, for /me). */
  getInstructorProfileByUserId(userId: number): Promise<Instructor | null>;
  /** Listed instructors with non-null lat/lng within a lat/lng bounding box (for nearby search). Includes user.name, user.surname. */
  findListedInBounds(latMin: number, latMax: number, lngMin: number, lngMax: number): Promise<Array<Instructor & { user: { name: string; surname: string } }>>;
  updateInstructor(id: number, data: Partial<Instructor>): Promise<Instructor>
  updateDocument(id: number, documentType: string, filename: string): Promise<Instructor>
  /** Marca documento como pendiente de revisión tras un upload. */
  upsertDocumentReviewPending(instructorId: number, documentType: string): Promise<void>
  // Listar todos los instructores (con filtros opcionales)
  listInstructors(filter?: {
    available?: boolean;
    isValid?: boolean;
  }): Promise<Instructor[]>;

  registerPermission(idInstructor: number, permissionId: number): Promise<void>;

  // Asignar permiso a un instructor
  addPermission(instructorId: number, permissionId: number): Promise<void>;

  // Revocar permiso de un instructor
  removePermission(instructorId: number, permissionId: number): Promise<void>;

  // Validar instructor (set isValid = true)
  validateInstructor(instructorId: number): Promise<Instructor>;

  // Verificar si un instructor tiene todos los permisos obligatorios
  hasAllMandatoryPermissions(instructorId: number): Promise<boolean>;
}
