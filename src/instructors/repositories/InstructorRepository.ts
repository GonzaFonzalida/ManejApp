import { Instructor } from "@prisma/client";

export interface InstructorRepository {
  createInstructor(data: {
    userId: number;
    licenseNumber: string;
    experienceYears: number;
  }): Promise<Instructor>;

  getInstructorById(id: number): Promise<Instructor | null>;
  updateInstructor(id: number, data: Partial<Instructor>): Promise<Instructor>
  // Listar todos los instructores (con filtros opcionales)
  listInstructors(filter?: {
    available?: boolean;
    isValid?: boolean;
  }): Promise<Instructor[]>;

  registerPermission(idInstructor: number,  permissionId: number): Promise<void>;

  // Asignar permiso a un instructor
  addPermission(instructorId: number, permissionId: number): Promise<void>;

  // Revocar permiso de un instructor
  removePermission(instructorId: number, permissionId: number): Promise<void>;

  // Validar instructor (set isValid = true)
  validateInstructor(instructorId: number): Promise<Instructor>;

  // Verificar si un instructor tiene todos los permisos obligatorios
  hasAllMandatoryPermissions(instructorId: number): Promise<boolean>;
}
