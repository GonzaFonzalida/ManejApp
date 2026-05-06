import request from "supertest";
import bcrypt from "bcryptjs";
import { randomUUID } from "crypto";
import { buildApp } from "../../src/app";
import { prisma } from "../../src/config/prismaClient";
import { clearDatabase } from "../helpers/db-cleaner";
import { BookingStatus, Role, SlotStatus } from "@prisma/client";
import MercadoPagoService from "../../src/modules/payments/mercadopago.service";
import { signMercadoPagoWebhookTestPayload } from "../../src/modules/payments/mercadopago-webhook.signature";
import { InstructorPayoutStatus } from "../../src/modules/payments/payment-commission.policy";

const app = buildApp();

let seq = 0;
function nextSeq() {
  seq += 1;
  return seq;
}

async function createInstructor() {
  const id = nextSeq();
  const hashedPassword = await bcrypt.hash("password123", 10);
  const email = `pay_inst_${id}@example.com`;
  const user = await prisma.user.create({
    data: {
      name: "Inst",
      surname: `${id}`,
      email,
      dni: `800${id}`,
      password: hashedPassword,
      role: Role.INSTRUCTOR,
      birthDate: new Date("1980-01-01"),
      emailVerifiedAt: new Date(),
      isActive: true,
    },
  });
  const instructor = await prisma.instructor.create({
    data: {
      userId: user.id,
      licenseNumber: `LIC-P${id}`,
      experienceYears: 4,
    },
  });
  const loginRes = await request(app).post("/api/v1/auth/login").send({
    email,
    password: "password123",
  });
  return { user, instructor, token: loginRes.body.accessToken as string };
}

async function createStudent() {
  const id = nextSeq();
  const hashedPassword = await bcrypt.hash("password123", 10);
  const email = `pay_stu_${id}@example.com`;
  const user = await prisma.user.create({
    data: {
      name: "Stu",
      surname: `${id}`,
      email,
      dni: `900${id}`,
      password: hashedPassword,
      role: Role.STUDENT,
      birthDate: new Date("2000-01-01"),
      emailVerifiedAt: new Date(),
      isActive: true,
    },
  });
  const student = await prisma.student.create({ data: { userId: user.id } });
  const loginRes = await request(app).post("/api/v1/auth/login").send({
    email,
    password: "password123",
  });
  return { user, student, token: loginRes.body.accessToken as string };
}

async function createAdminUser() {
  const id = nextSeq();
  const password = "adminpw123";
  const email = `pay_adm_${id}@example.com`;
  const user = await prisma.user.create({
    data: {
      name: "Adm",
      surname: `${id}`,
      email,
      dni: `700${id}`,
      password: await bcrypt.hash(password, 10),
      role: Role.ADMIN,
      birthDate: new Date("1985-01-01"),
      emailVerifiedAt: new Date(),
      isActive: true,
    },
  });
  const loginRes = await request(app).post("/api/v1/auth/login").send({
    email,
    password,
  });
  return { user, token: loginRes.body.accessToken as string };
}

function signedMpWebhook(body: { type: string; data: { id: string | number } }) {
  const secret = process.env.MERCADOPAGO_WEBHOOK_SECRET!;
  const requestId = randomUUID();
  const dataId = String(body.data.id).toLowerCase();
  const sig = signMercadoPagoWebhookTestPayload({
    secret,
    dataId,
    requestId,
  });
  return request(app)
    .post("/api/v1/payments/mercadopago/webhook")
    .set("x-signature", sig["x-signature"])
    .set("x-request-id", sig["x-request-id"])
    .send(body);
}

describe("Payments HTTP integration", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it("GET /api/v1/payments sin auth → 401", async () => {
    const res = await request(app).get("/api/v1/payments");
    expect(res.status).toBe(401);
  });

  it("GET /api/v1/payments con estudiante devuelve envelope { success, data }", async () => {
    const { token } = await createStudent();
    const res = await request(app)
      .get("/api/v1/payments")
      .set("Authorization", `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it("GET /api/v1/payments/driving-class/:id devuelve lista de pagos", async () => {
    const { instructor } = await createInstructor();
    const { student, token: studentToken } = await createStudent();
    const startsAt = new Date(Date.now() + 48 * 60 * 60 * 1000);
    const booking = await prisma.drivingClass.create({
      data: {
        studentId: student.id,
        instructorId: instructor.id,
        date: startsAt,
        duration: 60,
        status: BookingStatus.PENDING_PAYMENT,
        amount: 8000,
        currency: "ARS",
      },
    });
    await prisma.payment.create({
      data: {
        amount: 8000,
        status: "pending",
        paymentMethod: "mercadopago",
        provider: "mercadopago",
        drivingClassId: booking.id,
      },
    });

    const res = await request(app)
      .get(`/api/v1/payments/driving-class/${booking.id}`)
      .set("Authorization", `Bearer ${studentToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBe(1);
  });

  it("POST /api/v1/payments/mercadopago/preference → 403 si no es STUDENT", async () => {
    const { instructor, token } = await createInstructor();
    const res = await request(app)
      .post("/api/v1/payments/mercadopago/preference")
      .set("Authorization", `Bearer ${token}`)
      .send({ drivingClassId: 999 });
    expect(res.status).toBe(403);
  });

  it("POST /api/v1/payments/mercadopago/preference → 404 reserva inexistente", async () => {
    const { token } = await createStudent();
    const res = await request(app)
      .post("/api/v1/payments/mercadopago/preference")
      .set("Authorization", `Bearer ${token}`)
      .send({ drivingClassId: 999999 });
    expect(res.status).toBe(404);
  });

  it("POST /api/v1/payments/mercadopago/preference → 403 si el alumno no es dueño", async () => {
    const { instructor } = await createInstructor();
    const { student } = await createStudent();
    const { token: otherToken } = await createStudent();
    const startsAt = new Date(Date.now() + 48 * 60 * 60 * 1000);
    const booking = await prisma.drivingClass.create({
      data: {
        studentId: student.id,
        instructorId: instructor.id,
        date: startsAt,
        duration: 60,
        status: BookingStatus.PENDING_PAYMENT,
        amount: 5000,
        currency: "ARS",
      },
    });
    await prisma.scheduleSlot.create({
      data: {
        instructorId: instructor.id,
        startTime: startsAt,
        endTime: new Date(startsAt.getTime() + 60 * 60 * 1000),
        status: SlotStatus.HELD,
        heldUntil: new Date(Date.now() + 10 * 60 * 1000),
        drivingClassId: booking.id,
      },
    });
    await prisma.payment.create({
      data: {
        amount: 5000,
        status: "pending",
        paymentMethod: "mercadopago",
        provider: "mercadopago",
        drivingClassId: booking.id,
      },
    });

    const res = await request(app)
      .post("/api/v1/payments/mercadopago/preference")
      .set("Authorization", `Bearer ${otherToken}`)
      .send({ drivingClassId: booking.id });
    expect(res.status).toBe(403);
  });

  it("POST /api/v1/payments/mercadopago/webhook → 401 sin firma (con secreto configurado)", async () => {
    const res = await request(app)
      .post("/api/v1/payments/mercadopago/webhook")
      .send({ type: "payment", data: { id: "123" } });
    expect(res.status).toBe(401);
  });

  it("POST /api/v1/payments/mercadopago/webhook → 401 firma incorrecta", async () => {
    const body = { type: "payment", data: { id: "999" } };
    const res = await request(app)
      .post("/api/v1/payments/mercadopago/webhook")
      .set("x-signature", "ts=1,v1=invalid")
      .set("x-request-id", randomUUID())
      .send(body);
    expect(res.status).toBe(401);
  });

  it("POST /api/v1/payments/mercadopago/webhook firma válida → 200 tolerante si MP no devuelve pago", async () => {
    jest.spyOn(MercadoPagoService.prototype, "getPayment").mockRejectedValue(new Error("mp skip"));
    const res = await signedMpWebhook({
      type: "payment",
      data: { id: "test-mp-id-unknown" },
    });
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
  });

  it("webhook approved persiste comisión, neto instructor y payout interno", async () => {
    const { instructor } = await createInstructor();
    const { student } = await createStudent();
    const startsAt = new Date(Date.now() + 48 * 60 * 60 * 1000);
    const booking = await prisma.drivingClass.create({
      data: {
        studentId: student.id,
        instructorId: instructor.id,
        date: startsAt,
        duration: 60,
        status: BookingStatus.PENDING_PAYMENT,
        amount: 10000,
        currency: "ARS",
      },
    });
    await prisma.scheduleSlot.create({
      data: {
        instructorId: instructor.id,
        startTime: startsAt,
        endTime: new Date(startsAt.getTime() + 60 * 60 * 1000),
        status: SlotStatus.HELD,
        heldUntil: new Date(Date.now() + 10 * 60 * 1000),
        drivingClassId: booking.id,
      },
    });
    await prisma.payment.create({
      data: {
        amount: 10000,
        status: "pending",
        paymentMethod: "mercadopago",
        provider: "mercadopago",
        drivingClassId: booking.id,
        externalReference: String(booking.id),
        commissionRate: 20,
        appCommission: 2000,
        instructorAmount: 8000,
      },
    });

    const mpPaymentResourceId = "mp-res-webhook-1";
    jest.spyOn(MercadoPagoService.prototype, "getPayment").mockResolvedValue({
      id: mpPaymentResourceId,
      status: "approved",
      external_reference: String(booking.id),
      transaction_amount: 10000,
    });

    const res = await signedMpWebhook({
      type: "payment",
      data: { id: mpPaymentResourceId },
    });
    expect(res.status).toBe(200);

    const pay = await prisma.payment.findFirst({
      where: { drivingClassId: booking.id },
    });
    expect(pay?.status).toBe("paid");
    expect(pay?.paymentId).toBe(mpPaymentResourceId);
    expect(pay?.appCommission).toBe(2000);
    expect(pay?.instructorAmount).toBe(8000);
    expect(pay?.commissionRate).toBe(20);
    expect(pay?.mpTransactionAmount).toBe(10000);
    expect(pay?.instructorPayoutStatus).toBe(InstructorPayoutStatus.PENDING_INTERNAL_PAYOUT);

    const res2 = await signedMpWebhook({
      type: "payment",
      data: { id: mpPaymentResourceId },
    });
    expect(res2.status).toBe(200);
    const payAfter = await prisma.payment.findFirst({
      where: { drivingClassId: booking.id },
    });
    expect(payAfter?.paymentId).toBe(mpPaymentResourceId);
    expect(payAfter?.status).toBe("paid");
  });

  it("GET /api/v1/payments/commission-report → 403 para estudiante", async () => {
    const { token } = await createStudent();
    const res = await request(app)
      .get("/api/v1/payments/commission-report")
      .set("Authorization", `Bearer ${token}`);
    expect(res.status).toBe(403);
  });

  it("GET /api/v1/admin/payments/reconciliation → 200 admin con totales", async () => {
    const { instructor } = await createInstructor();
    const { student } = await createStudent();
    const startsAt = new Date(Date.now() + 48 * 60 * 60 * 1000);
    const booking = await prisma.drivingClass.create({
      data: {
        studentId: student.id,
        instructorId: instructor.id,
        date: startsAt,
        duration: 60,
        status: BookingStatus.CONFIRMED,
        amount: 5000,
        currency: "ARS",
      },
    });
    await prisma.payment.create({
      data: {
        amount: 5000,
        status: "paid",
        paymentMethod: "mercadopago",
        provider: "mercadopago",
        drivingClassId: booking.id,
        appCommission: 1000,
        instructorAmount: 4000,
        commissionRate: 20,
        mpTransactionAmount: 5000,
        instructorPayoutStatus: InstructorPayoutStatus.PENDING_INTERNAL_PAYOUT,
      },
    });

    const { token: adminToken } = await createAdminUser();
    const res = await request(app)
      .get("/api/v1/admin/payments/reconciliation")
      .set("Authorization", `Bearer ${adminToken}`);
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.paidCount).toBeGreaterThanOrEqual(1);
    expect(res.body.data.sums.grossRegistered).toBeGreaterThanOrEqual(5000);
    expect(res.body.data.anomalies.paidMissingCommissionFields).toBe(0);
  });
});
