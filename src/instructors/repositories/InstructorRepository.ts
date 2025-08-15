import { Instructor, Permission, Car } from "@prisma/client";

export interface InstructorRepository {
  createInstructor(data: {
    userId: number;
    licenseNumber: string;
    experienceYears: number;
    carId?: number;
  }): Promise<Instructor>;

  getInstructorById(id: number): Promise<Instructor | null>;
  updateInstructor(id: number, data: Partial<Instructor>): Promise<Instructor>
  // Listar todos los instructores (con filtros opcionales)
  listInstructors(filter?: {
    available?: boolean;
    isValid?: boolean;
  }): Promise<Instructor[]>;

  // Asignar un auto a un instructor
  assignCar(instrucWWtorId: number, carId: number): Promise<Instructor>;

  // Quitar auto de un instructor
  removeCar(instructorId: number): Promise<Instructor>;

  // Asignar permiso a un instructor
  addPermission(instructorId: number, permissionId: number): Promise<void>;

  // Revocar permiso de un instructor
  removePermission(instructorId: number, permissionId: number): Promise<void>;

  // Validar instructor (set isValid = true)
  validateInstructor(instructorId: number): Promise<Instructor>;

  // Verificar si un instructor tiene todos los permisos obligatorios
  hasAllMandatoryPermissions(instructorId: number): Promise<boolean>;
}
