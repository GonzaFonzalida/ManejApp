// src/modules/drivingClass/repositories/PrismaDrivingClassRepository.ts
import { DrivingClassRepository } from "./DrivingClassRepository";
import { DrivingClass } from "../entities/DrivingClass";
import { prisma } from "@config/prismaClient";

export class PrismaDrivingClassRepository implements DrivingClassRepository {
    private prisma = prisma;
    constructor() {}

    async create(data: Omit<DrivingClass, "id">): Promise<DrivingClass> {
     return this.prisma.drivingClass.create({
        data: {
        ...data,
        date: new Date(data.date), // convierte string -> Date
        },
    });
    }

  async findById(id: number): Promise<DrivingClass | null> {
    return this.prisma.drivingClass.findUnique({ where: { id } });
  }

  async findAll(): Promise<DrivingClass[]> {
    const rows = await this.prisma.drivingClass.findMany({
      include: {
        student: { include: { user: true } },
      },
      orderBy: { date: "desc" },
    });

    return rows.map((row) => {
      const { student: st, ...rest } = row;
      let studentPayload: Record<string, unknown> | undefined;
      if (st?.user) {
        studentPayload = {
          id: st.user.id,
          name: st.user.name,
          surname: st.user.surname,
          email: st.user.email,
          role: st.user.role,
          experienceLevel: st.experienceLevel,
        };
      }
      return {
        ...rest,
        student: studentPayload,
      } as unknown as DrivingClass;
    });
  }

  async update(id: number, data: Partial<DrivingClass>): Promise<DrivingClass> {
    return this.prisma.drivingClass.update({ where: { id }, data });
  }

  async delete(id: number): Promise<void> {
    await this.prisma.drivingClass.delete({ where: { id } });
  }
}
