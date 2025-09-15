// src/modules/drivingClass/services/DrivingClassService.ts
import { DrivingClassRepository } from "./repositories/DrivingClassRepository";
import { DrivingClass } from "./entities/DrivingClass";
import { UserRepository } from "../users/repositories/userRepository";
import { prisma } from "@config/prismaClient";
import PrismaInstructorRepository from "../instructors/repositories/PrismaInstructorRepository";
import CustomizedError from "@shared/classes/CustomizedError";

export class DrivingClassService {
  constructor(
    private readonly userRepo: UserRepository,
    private readonly instructorRepo: PrismaInstructorRepository,
    private readonly drivingClassRepo: DrivingClassRepository
  ) {}

async create(data: Omit<DrivingClass, "id" | "createdAt" | "updatedAt">): Promise<DrivingClass> {
  try {
    // Validar que el estudiante exista en Student
    const studentExists = await prisma.student.findUnique({
      where: { id: data.studentId }
    });
    if (!studentExists) throw new CustomizedError("El estudiante no existe", 409);

    // Validar que el instructor exista
    const instructorExists = await prisma.instructor.findUnique({
      where: { id: data.instructorId }
    });
    if (!instructorExists) throw new CustomizedError("El instructor no existe", 409);

    // Crear la clase
    return await prisma.drivingClass.create({
      data: {
        studentId: data.studentId,
        instructorId: data.instructorId,
        date: new Date(data.date),
        duration: data.duration,
        status: data.status,
      }
    });

  } catch (e: any) {
    if (e.code === "P2003") {
      throw new CustomizedError("Violación de clave foránea: estudiante o instructor no existe", 409);
    }
    throw e;
  }
}

  async listClasses(): Promise<DrivingClass[]> {
    return this.drivingClassRepo.findAll();
  }

  async getClassById(id: number): Promise<DrivingClass | null> {
    return this.drivingClassRepo.findById(id);
  }

  async updateClass(id: number, data: Partial<DrivingClass>): Promise<DrivingClass> {
    return this.drivingClassRepo.update(id, data);
  }

  async cancelClass(id: number): Promise<void> {
    await this.drivingClassRepo.update(id, { status: "cancelled" });
  }

  async deleteClass(id: number): Promise<void> {
    await this.drivingClassRepo.delete(id);
  }
}
