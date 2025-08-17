import { PrismaClient, Instructor } from "@prisma/client";
import  {InstructorRepository}  from "./InstructorRepository";
import * as config from "@config/prismaClient";
export default class PrismaInstructorRepository implements InstructorRepository {
  constructor() {}
    private prisma = config.prisma;
    async createInstructor(data: {
    userId: number;
    licenseNumber: string;
    experienceYears: number;
    carId?: number;
  }): Promise<Instructor> {
    return await this.prisma.instructor.create({
      data: {
        userId: data.userId,
        licenseNumber: data.licenseNumber,
        experienceYears: data.experienceYears,
        carId: data.carId,
      },
    });
  }


  async getInstructorById(id: number): Promise<Instructor | null> {
    return await this.prisma.instructor.findUnique({
      where: { id },
      include: { permissions: true, car: true, user: true },
    });
  }

  async listInstructors(filter?: { available?: boolean; isValid?: boolean }): Promise<Instructor[]> {
    return await this.prisma.instructor.findMany({
      where: filter,
      include: { permissions: true, car: true, user: true },
    });
  }

  async updateInstructor(id: number, data: Partial<Instructor>): Promise<Instructor> {
  return this.prisma.instructor.update({
    where: { id },
    data,
  });
  
}
  async assignCar(instructorId: number, carId: number): Promise<Instructor> {
    return await this.prisma.instructor.update({
      where: { id: instructorId },
      data: { carId },
      include: { car: true },
    });
  }

  async removeCar(instructorId: number): Promise<Instructor> {
    return await this.prisma.instructor.update({
      where: { id: instructorId },
      data: { carId: null },
      include: { car: true },
    });
  }

  async addPermission(instructorId: number, permissionId: number): Promise<void> {
    await this.prisma.instructorPermission.upsert({
      where: { instructorId_permissionId: { instructorId, permissionId } },
      update: { granted: true },
      create: { instructorId, permissionId, granted: true },
    });
  }

  async removePermission(instructorId: number, permissionId: number): Promise<void> {
    await this.prisma.instructorPermission.delete({
      where: { instructorId_permissionId: { instructorId, permissionId } },
    });
    
  }

  async validateInstructor(instructorId: number): Promise<Instructor> {
    return await this.prisma.instructor.update({
      where: { id: instructorId },
      data: { isValid: true },
    });
  }

  async hasAllMandatoryPermissions(instructorId: number): Promise<boolean> {
    const permissions = await this.prisma.instructorPermission.findMany({
      where: { instructorId },
      include: { permission: true },
    });

    return permissions
      .filter(p => p.permission.isMandatory)
      .every(p => p.granted);
  }
}
