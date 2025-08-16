import  {InstructorRepository} from "./repositories/InstructorRepository";
import {Instructor } from "@prisma/client";
import UserPrismaRepository from "src/users/repositories/prismaUserRepository";

export default class InstructorService {
  constructor(
    private instructorRepo: InstructorRepository,
    private userRepo : UserPrismaRepository
  ) {}

  async registerInstructor(data: {
  userId: number;
  licenseNumber: string;
  experienceYears: number;
  carId?: number;
}) {
  // Verificar que exista el usuario
  const user = await this.userRepo.findUser(String(data.userId));
  if (!user) throw new Error("Usuario no encontrado");


  if (user.role !== "STUDENT") {
    throw new Error("El usuario no puede registrarse como instructor");
  }

  // Verificar que no sea ya instructor
  const existingInstructor = await this.instructorRepo.getInstructorById(data.userId);
  if (existingInstructor) {
    throw new Error("Este usuario ya es instructor");
  }

  return this.instructorRepo.createInstructor(data);
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

  async assignCarToInstructor(instructorId: number, carId: number) {
    return this.instructorRepo.assignCar(instructorId, carId);
  }

  async removeCarFromInstructor(instructorId: number) {
    return this.instructorRepo.removeCar(instructorId);
  }

  async addPermission(instructorId: number, permissionId: number) {
    return this.instructorRepo.addPermission(instructorId, permissionId);
  }

  async validateIfHasAllPermissions(instructorId: number) {
    const hasAll = await this.instructorRepo.hasAllMandatoryPermissions(instructorId);
    if (hasAll) {
      return this.instructorRepo.validateInstructor(instructorId);
    }
    throw new Error("Instructor does not have all mandatory permissions.");
  }
}
