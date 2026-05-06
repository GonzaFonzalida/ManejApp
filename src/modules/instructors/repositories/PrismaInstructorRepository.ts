import { Instructor, InstructorDocumentReviewStatus, Prisma } from "@prisma/client";
import { InstructorRepository } from "./InstructorRepository";
import * as config from "@config/prismaClient";
export default class PrismaInstructorRepository implements InstructorRepository {
  constructor() { }
  private prisma = config.prisma;
  async createInstructor(data: {
    userId: number;
    licenseNumber?: string | null;
    experienceYears: number;
    hourlyRate?: number;
  }): Promise<Instructor> {
    return await this.prisma.instructor.create({
      data: {
        userId: data.userId,
        licenseNumber: data.licenseNumber ?? null,
        experienceYears: data.experienceYears,
        hourlyRate: data.hourlyRate,
      },
    });
  }


  async getInstructorById(id: number) {
    return await this.prisma.instructor.findUnique({
      where: { id },
      include: {
        permissions: true,
        cars: true,
        user: true,
        documentReviews: { select: { documentType: true, status: true } },
      },
    });
  }

  async getInstructorByUserId(userId: number): Promise<Instructor | null> {
    return await this.prisma.instructor.findUnique({ where: { userId } });
  }

  async getInstructorProfileByUserId(userId: number) {
    return await this.prisma.instructor.findUnique({
      where: { userId },
      include: { permissions: true, cars: true, user: true, documentReviews: true },
    });
  }

  async findListedInBounds(latMin: number, latMax: number, lngMin: number, lngMax: number) {
    return await this.prisma.instructor.findMany({
      where: {
        isListed: true,
        isValid: true,
        lat: { gte: latMin, lte: latMax },
        lng: { gte: lngMin, lte: lngMax },
      },
      include: {
        user: { select: { name: true, surname: true, profileImage: true } },
        documentReviews: { select: { documentType: true, status: true } },
      },
    }) as Array<
      Instructor & {
        user: { name: string; surname: string; profileImage: string | null };
        documentReviews: { documentType: string; status: InstructorDocumentReviewStatus }[];
      }
    >;
  }

  async listInstructors(filter?: {
    available?: boolean;
    isValid?: boolean;
    minPrice?: number;
    maxPrice?: number;
    transmission?: "MANUAL" | "AUTOMATIC";
    hasAvailability?: boolean;
  }): Promise<Instructor[]> {
    const where: any = {};

    if (filter?.available !== undefined) where.available = filter.available;
    if (filter?.isValid !== undefined) where.isValid = filter.isValid;

    if (filter?.minPrice != null || filter?.maxPrice != null) {
      where.hourlyRate = {};
      if (filter.minPrice != null) where.hourlyRate.gte = filter.minPrice;
      if (filter.maxPrice != null) where.hourlyRate.lte = filter.maxPrice;
    }

    if (filter?.transmission) {
      where.cars = { some: { transmission: filter.transmission, isActive: true } };
    }

    if (filter?.hasAvailability) {
      const now = new Date();
      where.scheduleSlots = {
        some: { status: "AVAILABLE", startTime: { gte: now } },
      };
    }

    return await this.prisma.instructor.findMany({
      where: Object.keys(where).length > 0 ? where : undefined,
      include: { permissions: true, cars: true, user: true },
    });
  }

  async updateInstructor(id: number, data: Partial<Instructor>): Promise<Instructor> {
    const { id: _omit, ...rest } = data;
    return this.prisma.instructor.update({
      where: { id },
      data: rest as Prisma.InstructorUpdateInput,
    });
  }

  async updateDocument(id: number, documentType: string, filename: string): Promise<Instructor> {
    return this.prisma.instructor.update({
      where: { id },
      data: {
        [documentType]: filename
      }
    });
  }

  async upsertDocumentReviewPending(instructorId: number, documentType: string): Promise<void> {
    await this.prisma.instructorDocumentReview.upsert({
      where: {
        instructorId_documentType: { instructorId, documentType },
      },
      create: {
        instructorId,
        documentType,
        status: InstructorDocumentReviewStatus.PENDING_REVIEW,
      },
      update: {
        status: InstructorDocumentReviewStatus.PENDING_REVIEW,
        rejectionReason: null,
      },
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
