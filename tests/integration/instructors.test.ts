import request from "supertest";
import bcrypt from "bcryptjs";
import { randomUUID } from "crypto";
import { buildApp } from "../../src/app";
import { prisma } from "../../src/config/prismaClient";
import { clearDatabase } from "../helpers/db-cleaner";
import { InstructorDocumentReviewStatus, Role } from "@prisma/client";

const app = buildApp();

async function createStudentUser() {
  const suffix = randomUUID().replace(/-/g, "").slice(0, 14);
  const hashedPassword = await bcrypt.hash("password123", 10);
  const email = `student_inst_${suffix}@example.com`;
  const user = await prisma.user.create({
    data: {
      name: "Student",
      surname: "Test",
      email,
      dni: `st${suffix}`,
      password: hashedPassword,
      role: Role.STUDENT,
      birthDate: new Date("2000-01-01"),
      emailVerifiedAt: new Date(),
      isActive: true,
    },
  });
  const loginRes = await request(app).post("/api/v1/auth/login").send({
    email,
    password: "password123",
  });
  return { user, token: loginRes.body.accessToken as string, email };
}

async function loginToken(email: string) {
  const loginRes = await request(app).post("/api/v1/auth/login").send({
    email,
    password: "password123",
  });
  return loginRes.body.accessToken as string;
}

async function createInstructorUserOnly() {
  const suffix = randomUUID().replace(/-/g, "").slice(0, 14);
  const hashedPassword = await bcrypt.hash("password123", 10);
  const email = `instr_only_${suffix}@example.com`;
  const user = await prisma.user.create({
    data: {
      name: "Instr",
      surname: "Only",
      email,
      dni: `io${suffix}`,
      password: hashedPassword,
      role: Role.INSTRUCTOR,
      birthDate: new Date("1980-01-01"),
      emailVerifiedAt: new Date(),
      isActive: true,
    },
  });
  return { user };
}

describe("Instructors HTTP integration", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it("POST /api/v1/instructors/register crea instructor y cambia rol a INSTRUCTOR", async () => {
    const { user, email } = await createStudentUser();

    const res = await request(app)
      .post("/api/v1/instructors/register")
      .send({
        userId: user.id,
        licenseNumber: "LIC-12345",
        experienceYears: 3,
        hourlyRate: 5000,
      });

    expect(res.status).toBe(201);
    expect(res.body).toHaveProperty("id");
    expect(res.body.userId).toBe(user.id);

    const updated = await prisma.user.findUnique({ where: { id: user.id } });
    expect(updated?.role).toBe(Role.INSTRUCTOR);

    const instructorToken = await loginToken(email);

    const me = await request(app)
      .get("/api/v1/instructors/me")
      .set("Authorization", `Bearer ${instructorToken}`);
    expect(me.status).toBe(200);
    expect(me.body).toHaveProperty("id");
  });

  it("POST /api/v1/instructors/register crea instructor sin licenseNumber (null en DB)", async () => {
    const { user, email } = await createStudentUser();

    const res = await request(app).post("/api/v1/instructors/register").send({
      userId: user.id,
      experienceYears: 4,
    });

    expect(res.status).toBe(201);
    const inst = await prisma.instructor.findUnique({ where: { userId: user.id } });
    expect(inst?.licenseNumber).toBeNull();

    const instructorToken = await loginToken(email);
    const me = await request(app)
      .get("/api/v1/instructors/me")
      .set("Authorization", `Bearer ${instructorToken}`);
    expect(me.status).toBe(200);
    expect(me.body.experienceYears).toBe(4);
  });

  it("POST /api/v1/instructors/register rechaza usuario que no es STUDENT", async () => {
    const { user } = await createInstructorUserOnly();

    const res = await request(app).post("/api/v1/instructors/register").send({
      userId: user.id,
      licenseNumber: "LIC-99999",
      experienceYears: 1,
    });

    expect(res.status).toBeGreaterThanOrEqual(400);
  });

  it("GET /api/v1/instructors/nearby exige lat y lng", async () => {
    const res = await request(app).get("/api/v1/instructors/nearby");
    expect([400, 422]).toContain(res.status);
  });

  it("GET /api/v1/instructors/nearby devuelve lista (vacía si no hay publicables)", async () => {
    const res = await request(app)
      .get("/api/v1/instructors/nearby")
      .query({ lat: -34.6, lng: -58.4, radiusKm: 5, limit: 20 });
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it("PUT /api/v1/instructors/me y PATCH /api/v1/instructors/me/listed actualizan perfil", async () => {
    const { user, email } = await createStudentUser();
    await request(app).post("/api/v1/instructors/register").send({
      userId: user.id,
      licenseNumber: "LIC-PUT01",
      experienceYears: 2,
    });

    const instructorToken = await loginToken(email);

    const put = await request(app)
      .put("/api/v1/instructors/me")
      .set("Authorization", `Bearer ${instructorToken}`)
      .send({
        bio: "Bio de prueba integración",
        lat: -34.6037,
        lng: -58.3816,
        hourlyRate: 4500,
      });
    expect(put.status).toBe(200);
    expect(put.body.bio).toContain("prueba");

    const patch = await request(app)
      .patch("/api/v1/instructors/me/listed")
      .set("Authorization", `Bearer ${instructorToken}`)
      .send({ isListed: false });
    expect(patch.status).toBe(200);
    expect(patch.body.isListed).toBe(false);
  });

  it("POST /api/v1/instructors/me/documents acepta imagen base64", async () => {
    const { user, email } = await createStudentUser();
    await request(app).post("/api/v1/instructors/register").send({
      userId: user.id,
      licenseNumber: "LIC-DOC01",
      experienceYears: 1,
    });
    const instructorToken = await loginToken(email);

    const pngBase64 =
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

    const res = await request(app)
      .post("/api/v1/instructors/me/documents")
      .set("Authorization", `Bearer ${instructorToken}`)
      .send({
        documentType: "vtvImg",
        image: pngBase64,
        mimeType: "image/png",
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data?.url).toBeTruthy();
  });

  it("GET /api/v1/instructors/me incluye onboarding con tres tracks", async () => {
    const { user, email } = await createStudentUser();
    await request(app).post("/api/v1/instructors/register").send({
      userId: user.id,
      licenseNumber: "LIC-ONB01",
      experienceYears: 2,
    });
    const instructorToken = await loginToken(email);
    const me = await request(app)
      .get("/api/v1/instructors/me")
      .set("Authorization", `Bearer ${instructorToken}`);
    expect(me.status).toBe(200);
    expect(me.body.onboarding).toBeDefined();
    expect(me.body.onboarding.documentTrack).toBeDefined();
    expect(me.body.onboarding.profileTrack).toBeDefined();
    expect(me.body.onboarding.activationTrack).toBeDefined();
  });

  it("PUT /api/v1/instructors/me permite actualizar perfil con documentación en PENDING_REVIEW", async () => {
    const { user, email } = await createStudentUser();
    await request(app).post("/api/v1/instructors/register").send({
      userId: user.id,
      licenseNumber: "LIC-PEND01",
      experienceYears: 2,
    });
    const instructorToken = await loginToken(email);
    const inst = await prisma.instructor.findUnique({ where: { userId: user.id } });
    expect(inst).not.toBeNull();
    await prisma.instructorDocumentReview.create({
      data: {
        instructorId: inst!.id,
        documentType: "vtvImg",
        status: InstructorDocumentReviewStatus.PENDING_REVIEW,
      },
    });

    const put = await request(app)
      .put("/api/v1/instructors/me")
      .set("Authorization", `Bearer ${instructorToken}`)
      .send({ bio: "Bio mientras doc pendiente" });
    expect(put.status).toBe(200);
    expect(put.body.bio).toContain("pendiente");
  });

  it("PUT /me + docs aprobados y perfil completo sincroniza isValid a true", async () => {
    const { user, email } = await createStudentUser();
    await request(app).post("/api/v1/instructors/register").send({
      userId: user.id,
      licenseNumber: "LIC-SYNC01",
      experienceYears: 3,
    });
    const inst = await prisma.instructor.findUnique({ where: { userId: user.id } });
    expect(inst).not.toBeNull();
    const basePath = "/api/v1/instructors/documents/x.png";
    await prisma.instructor.update({
      where: { id: inst!.id },
      data: {
        bio: "Completo",
        lat: -34.6,
        lng: -58.4,
        hourlyRate: 5000,
        dobleComandoImg: basePath,
        seguroImg: basePath,
        vtvImg: basePath,
        reincidenciaImg: basePath,
        licenciaImg: basePath,
        isValid: false,
      },
    });
    await prisma.user.update({
      where: { id: user.id },
      data: { profileImage: "/uploads/fake-profile.jpg" },
    });
    const types = [
      "dobleComandoImg",
      "seguroImg",
      "vtvImg",
      "reincidenciaImg",
      "licenciaImg",
    ] as const;
    for (const documentType of types) {
      await prisma.instructorDocumentReview.upsert({
        where: {
          instructorId_documentType: { instructorId: inst!.id, documentType },
        },
        create: {
          instructorId: inst!.id,
          documentType,
          status: InstructorDocumentReviewStatus.APPROVED,
        },
        update: { status: InstructorDocumentReviewStatus.APPROVED },
      });
    }
    const instructorToken = await loginToken(email);
    const put = await request(app)
      .put("/api/v1/instructors/me")
      .set("Authorization", `Bearer ${instructorToken}`)
      .send({ bio: "Bio sync" });
    expect(put.status).toBe(200);
    expect(put.body.isValid).toBe(true);
  });
});
