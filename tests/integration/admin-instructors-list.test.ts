import request from "supertest";
import bcrypt from "bcryptjs";
import { randomUUID } from "crypto";
import { buildApp } from "../../src/app";
import { prisma } from "../../src/config/prismaClient";
import { clearDatabase } from "../helpers/db-cleaner";
import { InstructorDocumentReviewStatus, Role } from "@prisma/client";

const app = buildApp();

describe("GET /api/v1/admin/instructors (document review list)", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it("documentReview=pending lista instructores con doc obligatorio subido y PENDING_REVIEW", async () => {
    const suffix = randomUUID().replace(/-/g, "").slice(0, 12);
    const adminPass = await bcrypt.hash("adminpass1", 10);
    const adminUser = await prisma.user.create({
      data: {
        name: "Admin",
        surname: "Test",
        email: `adm_${suffix}@example.com`,
        dni: `adm${suffix}`,
        password: adminPass,
        role: Role.ADMIN,
        birthDate: new Date("1985-01-01"),
        emailVerifiedAt: new Date(),
        isActive: true,
      },
    });

    const instrPass = await bcrypt.hash("instrpass1", 10);
    const instrUser = await prisma.user.create({
      data: {
        name: "Inst",
        surname: "Doc",
        email: `ins_${suffix}@example.com`,
        dni: `ins${suffix}`,
        password: instrPass,
        role: Role.INSTRUCTOR,
        birthDate: new Date("1980-01-01"),
        emailVerifiedAt: new Date(),
        isActive: true,
      },
    });

    const instructor = await prisma.instructor.create({
      data: {
        userId: instrUser.id,
        licenseNumber: "LIC-99999",
        experienceYears: 5,
        isValid: true,
        isListed: false,
        vtvImg: "/api/v1/instructors/documents/vtvImg-test.jpg",
      },
    });

    await prisma.instructorDocumentReview.create({
      data: {
        instructorId: instructor.id,
        documentType: "vtvImg",
        status: InstructorDocumentReviewStatus.PENDING_REVIEW,
      },
    });

    const login = await request(app).post("/api/v1/auth/login").send({
      email: adminUser.email,
      password: "adminpass1",
    });
    expect(login.status).toBe(200);
    const token = login.body.accessToken as string;

    const res = await request(app)
      .get("/api/v1/admin/instructors?documentReview=pending")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const list = res.body.data as any[];
    expect(Array.isArray(list)).toBe(true);
    expect(list.length).toBe(1);
    expect(list[0].id).toBe(instructor.id);
    expect(list[0].documentReviews?.length).toBeGreaterThanOrEqual(1);
    expect(list[0].documentReviewSummary?.pendingCount).toBeGreaterThanOrEqual(1);
    expect(list[0].documentReviewSummary?.hasPendingDocumentReview).toBe(true);
  });

  it("documentReview=pending no incluye instructor sin archivo para el doc pendiente", async () => {
    const suffix = randomUUID().replace(/-/g, "").slice(0, 12);
    const adminPass = await bcrypt.hash("adminpass2", 10);
    const adminUser = await prisma.user.create({
      data: {
        name: "Admin2",
        surname: "Test",
        email: `adm2_${suffix}@example.com`,
        dni: `ad2${suffix}`,
        password: adminPass,
        role: Role.ADMIN,
        birthDate: new Date("1985-01-01"),
        emailVerifiedAt: new Date(),
        isActive: true,
      },
    });

    const instrUser = await prisma.user.create({
      data: {
        name: "Inst2",
        surname: "NoFile",
        email: `ins2_${suffix}@example.com`,
        dni: `in2${suffix}`,
        password: await bcrypt.hash("p", 10),
        role: Role.INSTRUCTOR,
        birthDate: new Date("1980-01-01"),
        emailVerifiedAt: new Date(),
        isActive: true,
      },
    });

    const instructor = await prisma.instructor.create({
      data: {
        userId: instrUser.id,
        licenseNumber: "LIC-88888",
        experienceYears: 2,
        isValid: false,
        isListed: false,
        // sin vtvImg pero review pendiente (estado inconsistente — no debe aparecer en cola file-based)
        vtvImg: null,
      },
    });

    await prisma.instructorDocumentReview.create({
      data: {
        instructorId: instructor.id,
        documentType: "vtvImg",
        status: InstructorDocumentReviewStatus.PENDING_REVIEW,
      },
    });

    const login = await request(app).post("/api/v1/auth/login").send({
      email: adminUser.email,
      password: "adminpass2",
    });
    const token = login.body.accessToken as string;

    const res = await request(app)
      .get("/api/v1/admin/instructors?documentReview=pending")
      .set("Authorization", `Bearer ${token}`);

    expect(res.status).toBe(200);
    const list = res.body.data as any[];
    expect(list.find((x) => x.id === instructor.id)).toBeUndefined();
  });

  it("PATCH /admin/instructors/:id/status rechaza isListed true sin requisitos de publicación", async () => {
    const suffix = randomUUID().replace(/-/g, "").slice(0, 12);
    const adminPass = await bcrypt.hash("adminpass3", 10);
    const adminUser = await prisma.user.create({
      data: {
        name: "Admin3",
        surname: "Test",
        email: `adm3_${suffix}@example.com`,
        dni: `ad3${suffix}`,
        password: adminPass,
        role: Role.ADMIN,
        birthDate: new Date("1985-01-01"),
        emailVerifiedAt: new Date(),
        isActive: true,
      },
    });

    const instrUser = await prisma.user.create({
      data: {
        name: "Inst3",
        surname: "List",
        email: `ins3_${suffix}@example.com`,
        dni: `in3${suffix}`,
        password: await bcrypt.hash("p", 10),
        role: Role.INSTRUCTOR,
        birthDate: new Date("1980-01-01"),
        emailVerifiedAt: new Date(),
        isActive: true,
      },
    });

    const instructor = await prisma.instructor.create({
      data: {
        userId: instrUser.id,
        licenseNumber: "LIC-77777",
        experienceYears: 2,
        isValid: true,
        isListed: false,
      },
    });

    const login = await request(app).post("/api/v1/auth/login").send({
      email: adminUser.email,
      password: "adminpass3",
    });
    const token = login.body.accessToken as string;

    const res = await request(app)
      .patch(`/api/v1/admin/instructors/${instructor.id}/status`)
      .set("Authorization", `Bearer ${token}`)
      .send({ isListed: true });

    expect(res.status).toBe(422);
  });
});
