import bcrypt from "bcryptjs";
import { prisma } from "@config/prismaClient";
import { NODE_ENV } from "@config/config";

/**
 * En desarrollo, asegura un instructor y un alumno de demo (mismas credenciales que `scripts/seed-test-data.ts`)
 * para que el panel admin no quede vacío con una DB recién creada.
 * Producción: no hace nada. Deshabilitar: `ENSURE_DEMO_CATALOG=0`.
 */
export async function ensureDemoCatalog(): Promise<void> {
  if (NODE_ENV === "production") return;
  if (process.env.ENSURE_DEMO_CATALOG === "0") return;

  const password = await bcrypt.hash("123456", 10);

  const instructorUser = await prisma.user.upsert({
    where: { email: "instructor@test.com" },
    update: { password, isActive: true },
    create: {
      email: "instructor@test.com",
      password,
      name: "Juan",
      surname: "Instructor",
      dni: "11111111",
      birthDate: new Date("1990-01-01"),
      role: "INSTRUCTOR",
      isActive: true,
      instructor: {
        create: {
          licenseNumber: "L123456",
          experienceYears: 5,
          available: true,
          isValid: true,
        },
      },
    },
    include: { instructor: true },
  });

  if (!instructorUser.instructor) {
    const existing = await prisma.instructor.findUnique({ where: { userId: instructorUser.id } });
    if (!existing) {
      await prisma.instructor.create({
        data: {
          userId: instructorUser.id,
          licenseNumber: "L123456",
          experienceYears: 5,
          isValid: true,
          available: true,
        },
      });
    }
  }

  const studentUser = await prisma.user.upsert({
    where: { email: "student@test.com" },
    update: { password, isActive: true },
    create: {
      email: "student@test.com",
      password,
      name: "Maria",
      surname: "Estudiante",
      dni: "22222222",
      birthDate: new Date("2000-01-01"),
      role: "STUDENT",
      isActive: true,
      student: { create: {} },
    },
    include: { student: true },
  });

  if (!studentUser.student) {
    const existing = await prisma.student.findUnique({ where: { userId: studentUser.id } });
    if (!existing) {
      await prisma.student.create({
        data: { userId: studentUser.id },
      });
    }
  }

  console.log(
    "[ensureDemoCatalog] Demo: instructor@test.com y student@test.com (contraseña 123456)",
  );
}
