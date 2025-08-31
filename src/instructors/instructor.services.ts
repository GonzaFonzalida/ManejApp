import { InstructorRepository } from "./repositories/InstructorRepository";
import { Instructor } from "@prisma/client";
import CustomizedError from "@shared/classes/CustomizedError";
import { PermissionRepository } from "src/permissions/repositories/IPermissionsRepository";
import { UserRepository } from "src/users/repositories/userRepository";

export default class InstructorService {
  constructor(
    private instructorRepo: InstructorRepository,
    private userRepo: UserRepository,
    private permissionRepo: PermissionRepository,
  ) {}

  async registerInstructor(data: {
    userId: number;
    licenseNumber: string;
    experienceYears: number;
    carId?: number;
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

    // 4. Obtener todos los permisos de la tabla Permission
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

  async listInstructors(filter?: { available?: boolean; isValid?: boolean }) {
    return this.instructorRepo.listInstructors();
  }

  async updateInstructor(
    id: number,
    data: Partial<Instructor>
  ): Promise<Instructor | null> {
    return this.instructorRepo.updateInstructor(id, data);
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
