import { Instructor } from "@prisma/client";
import  {InstructorRepository}  from "./InstructorRepository";
import * as config from "@config/prismaClient";
export default class PrismaInstructorRepository implements InstructorRepository {
  constructor() {}
    private prisma = config.prisma;
    async createInstructor(data: {
    userId: number;
    licenseNumber: string;
    experienceYears: number;
  }): Promise<Instructor> {
    return await this.prisma.instructor.create({
      data: {
        userId: data.userId,
        licenseNumber: data.licenseNumber,
        experienceYears: data.experienceYears,
       
      },
    });
  }


  async getInstructorById(id: number) {
    return await this.prisma.instructor.findUnique({
      where: { id },
      include: { permissions: true, cars: true, user: true },
    });
  }

  async getInstructorByUserId(userId: number): Promise<Instructor | null> {
    return await this.prisma.instructor.findUnique({ where: { userId } });
  }

  async listInstructors(filter?: { available?: boolean; isValid?: boolean }): Promise<Instructor[]> {
    return await this.prisma.instructor.findMany({
      where: filter,
      include: { permissions: true, cars: true, user: true },
    });
  }

  async updateInstructor(id: number, data: Partial<Instructor>): Promise<Instructor> {
    return this.prisma.instructor.update({
      where: { id },
      data,
    });
  }

  async addPermission(instructorId: number, permissionId: number): Promise<void> {
    await this.prisma.instructorPermission.upsert({
      where: { instructorId_permissionId: { instructorId, permissionId } },
      update: { granted: true },
      create: { instructorId, permissionId, granted: false },
    });
  }

  async removePermission(instructorId: number, permissionId: number): Promise<void> {
    await this.prisma.instructorPermission.delete({
      where: { instructorId_permissionId: { instructorId, permissionId } },
    });
    
  }

  async registerPermission(instructorId: number, permissionId: number): Promise<void> {
    const data = {
      instructorId,
      permissionId,
      granted: false
    };

    await this.prisma.instructorPermission.create({
      data
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
