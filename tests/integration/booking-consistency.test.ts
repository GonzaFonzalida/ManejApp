import request from "supertest";
import bcrypt from "bcryptjs";
import { buildApp } from "../../src/app";
import { prisma } from "../../src/config/prismaClient";
import { clearDatabase } from "../helpers/db-cleaner";
import PaymentService from "../../src/modules/payments/payment.services";
import PrismaPaymentRepository from "../../src/modules/payments/repositories/PrismaPaymentRepository";
import { BookingStatus, SlotStatus } from "@prisma/client";

const app = buildApp();

let seq = 0;
function nextSeq() {
  seq += 1;
  return seq;
}

async function createInstructor() {
  const id = nextSeq();
  const hashedPassword = await bcrypt.hash("password123", 10);
  const email = `instructor${id}@example.com`;

  const user = await prisma.user.create({
    data: {
      name: "Instructor",
      surname: `${id}`,
      email,
      dni: `3000${id}`,
      password: hashedPassword,
      role: "INSTRUCTOR",
      birthDate: new Date("1980-01-01"),
      emailVerifiedAt: new Date(),
      isActive: true,
    },
  });

  const instructor = await prisma.instructor.create({
    data: {
      userId: user.id,
      licenseNumber: `LIC-${id}`,
      experienceYears: 5,
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
  const email = `student${id}@example.com`;

  const user = await prisma.user.create({
    data: {
      name: "Student",
      surname: `${id}`,
      email,
      dni: `4000${id}`,
      password: hashedPassword,
      role: "STUDENT",
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

async function createAvailableSlot(instructorId: number) {
  const startTime = new Date();
  startTime.setHours(startTime.getHours() + 48);
  const endTime = new Date(startTime);
  endTime.setHours(startTime.getHours() + 1);

  return prisma.scheduleSlot.create({
    data: {
      instructorId,
      startTime,
      endTime,
      status: SlotStatus.AVAILABLE,
    },
  });
}

describe("Booking consistency integration", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it("evita doble reserva del mismo slot en concurrencia", async () => {
    const { instructor } = await createInstructor();
    const { token: studentTokenA } = await createStudent();
    const { token: studentTokenB } = await createStudent();
    const slot = await createAvailableSlot(instructor.id);

    const [resA, resB] = await Promise.all([
      request(app).post(`/api/v1/schedule/reserve/${slot.id}`).set("Authorization", `Bearer ${studentTokenA}`),
      request(app).post(`/api/v1/schedule/reserve/${slot.id}`).set("Authorization", `Bearer ${studentTokenB}`),
    ]);

    const statuses = [resA.status, resB.status].sort();
    expect(statuses).toEqual([201, 409]);

    const dbSlot = await prisma.scheduleSlot.findUnique({ where: { id: slot.id } });
    expect(dbSlot?.status).toBe(SlotStatus.HELD);
    expect(dbSlot?.drivingClassId).toBeTruthy();

    const classes = await prisma.drivingClass.findMany();
    expect(classes).toHaveLength(1);
    expect(classes[0].status).toBe(BookingStatus.PENDING_PAYMENT);
  });

  it("si el HELD expiró, recicla slot y cancela booking/pago previos", async () => {
    const { instructor } = await createInstructor();
    const { token: studentToken1 } = await createStudent();
    const { token: studentToken2 } = await createStudent();
    const slot = await createAvailableSlot(instructor.id);

    const firstReserve = await request(app)
      .post(`/api/v1/schedule/reserve/${slot.id}`)
      .set("Authorization", `Bearer ${studentToken1}`);
    expect(firstReserve.status).toBe(201);
    const oldBookingId = Number(firstReserve.body.bookingId);

    await prisma.scheduleSlot.update({
      where: { id: slot.id },
      data: {
        status: SlotStatus.HELD,
        heldUntil: new Date(Date.now() - 60_000),
      },
    });

    const secondReserve = await request(app)
      .post(`/api/v1/schedule/reserve/${slot.id}`)
      .set("Authorization", `Bearer ${studentToken2}`);
    expect(secondReserve.status).toBe(201);
    const newBookingId = Number(secondReserve.body.bookingId);
    expect(newBookingId).not.toBe(oldBookingId);

    const oldBooking = await prisma.drivingClass.findUnique({ where: { id: oldBookingId } });
    const oldPayment = await prisma.payment.findFirst({ where: { drivingClassId: oldBookingId } });
    const newBooking = await prisma.drivingClass.findUnique({ where: { id: newBookingId } });
    const updatedSlot = await prisma.scheduleSlot.findUnique({ where: { id: slot.id } });

    expect(oldBooking?.status).toBe(BookingStatus.CANCELLED);
    expect(oldPayment?.status).toBe("cancelled");
    expect(newBooking?.status).toBe(BookingStatus.PENDING_PAYMENT);
    expect(updatedSlot?.drivingClassId).toBe(newBookingId);
  });

  it("cancelación de clase confirmada deja clase/slot/pago consistentes", async () => {
    const { instructor } = await createInstructor();
    const { token: studentToken } = await createStudent();
    const slot = await createAvailableSlot(instructor.id);

    const reserve = await request(app)
      .post(`/api/v1/schedule/reserve/${slot.id}`)
      .set("Authorization", `Bearer ${studentToken}`);
    expect(reserve.status).toBe(201);
    const bookingId = Number(reserve.body.bookingId);

    await prisma.drivingClass.update({
      where: { id: bookingId },
      data: { status: BookingStatus.CONFIRMED },
    });
    await prisma.scheduleSlot.update({
      where: { id: slot.id },
      data: { status: SlotStatus.BOOKED, heldUntil: null },
    });
    await prisma.payment.updateMany({
      where: { drivingClassId: bookingId },
      data: { status: "paid" },
    });

    const cancelRes = await request(app)
      .patch(`/api/v1/classes/${bookingId}/cancel`)
      .set("Authorization", `Bearer ${studentToken}`);
    expect(cancelRes.status).toBe(200);
    expect(cancelRes.body.success).toBe(true);

    const booking = await prisma.drivingClass.findUnique({ where: { id: bookingId } });
    const payment = await prisma.payment.findFirst({ where: { drivingClassId: bookingId } });
    const dbSlot = await prisma.scheduleSlot.findUnique({ where: { id: slot.id } });

    expect(booking?.status).toBe(BookingStatus.CANCELLED);
    expect(payment?.status).toBe("cancelled");
    expect(dbSlot?.status).toBe(SlotStatus.AVAILABLE);
    expect(dbSlot?.drivingClassId).toBeNull();
  });

  it("cancelación con pago pendiente deja todo consistente", async () => {
    const { instructor } = await createInstructor();
    const { token: studentToken } = await createStudent();
    const slot = await createAvailableSlot(instructor.id);

    const reserve = await request(app)
      .post(`/api/v1/schedule/reserve/${slot.id}`)
      .set("Authorization", `Bearer ${studentToken}`);
    expect(reserve.status).toBe(201);
    const bookingId = Number(reserve.body.bookingId);

    const cancelRes = await request(app)
      .patch(`/api/v1/classes/${bookingId}/cancel`)
      .set("Authorization", `Bearer ${studentToken}`);
    expect(cancelRes.status).toBe(200);

    const booking = await prisma.drivingClass.findUnique({ where: { id: bookingId } });
    const payment = await prisma.payment.findFirst({ where: { drivingClassId: bookingId } });
    const dbSlot = await prisma.scheduleSlot.findUnique({ where: { id: slot.id } });

    expect(booking?.status).toBe(BookingStatus.CANCELLED);
    expect(payment?.status).toBe("cancelled");
    expect(dbSlot?.status).toBe(SlotStatus.AVAILABLE);
    expect(dbSlot?.drivingClassId).toBeNull();
  });

  it("webhook tardío aprobado no reabre una reserva cancelada", async () => {
    const { instructor } = await createInstructor();
    const { token: studentToken } = await createStudent();
    const slot = await createAvailableSlot(instructor.id);

    const reserve = await request(app)
      .post(`/api/v1/schedule/reserve/${slot.id}`)
      .set("Authorization", `Bearer ${studentToken}`);
    expect(reserve.status).toBe(201);
    const bookingId = Number(reserve.body.bookingId);

    await prisma.payment.updateMany({
      where: { drivingClassId: bookingId },
      data: { externalReference: String(bookingId) },
    });

    await request(app)
      .patch(`/api/v1/classes/${bookingId}/cancel`)
      .set("Authorization", `Bearer ${studentToken}`);

    const paymentRepo = new PrismaPaymentRepository();
    const fakeMercadoPagoService = {
      getPayment: jest.fn().mockResolvedValue({
        id: "mp-late-approved",
        status: "approved",
        external_reference: String(bookingId),
      }),
    } as any;
    const fakeNotificationService = {
      sendPushToUser: jest.fn().mockResolvedValue(undefined),
    } as any;
    const paymentService = new PaymentService(
      paymentRepo,
      fakeMercadoPagoService,
      fakeNotificationService
    );
    await paymentService.handleMercadoPagoWebhook({
      type: "payment",
      data: { id: "mp-late-approved" },
    });

    const booking = await prisma.drivingClass.findUnique({ where: { id: bookingId } });
    const payment = await prisma.payment.findFirst({ where: { drivingClassId: bookingId } });
    const dbSlot = await prisma.scheduleSlot.findUnique({ where: { id: slot.id } });

    expect(booking?.status).toBe(BookingStatus.CANCELLED);
    expect(payment?.status).toBe("cancelled");
    expect(dbSlot?.status).toBe(SlotStatus.AVAILABLE);
    expect(dbSlot?.drivingClassId).toBeNull();
  });

  it("lectura por rol expone solo próximas/historial/detalle autorizados", async () => {
    const { instructor, token: instructorToken } = await createInstructor();
    const { student, token: studentToken } = await createStudent();
    const { token: otherStudentToken } = await createStudent();

    const now = new Date();
    const pastDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const futureDate = new Date(now.getTime() + 24 * 60 * 60 * 1000);

    const completedClass = await prisma.drivingClass.create({
      data: {
        studentId: student.id,
        instructorId: instructor.id,
        date: pastDate,
        duration: 60,
        status: BookingStatus.COMPLETED,
        amount: 1000,
        currency: "ARS",
      },
    });

    const confirmedClass = await prisma.drivingClass.create({
      data: {
        studentId: student.id,
        instructorId: instructor.id,
        date: futureDate,
        duration: 60,
        status: BookingStatus.CONFIRMED,
        amount: 1200,
        currency: "ARS",
      },
    });

    const studentUpcoming = await request(app)
      .get("/api/v1/classes/upcoming")
      .set("Authorization", `Bearer ${studentToken}`);
    expect(studentUpcoming.status).toBe(200);
    expect(studentUpcoming.body.map((c: any) => c.id)).toEqual([confirmedClass.id]);

    const studentHistory = await request(app)
      .get("/api/v1/classes/history")
      .set("Authorization", `Bearer ${studentToken}`);
    expect(studentHistory.status).toBe(200);
    expect(studentHistory.body.map((c: any) => c.id)).toEqual([completedClass.id]);

    const instructorUpcoming = await request(app)
      .get("/api/v1/classes/upcoming")
      .set("Authorization", `Bearer ${instructorToken}`);
    expect(instructorUpcoming.status).toBe(200);
    expect(instructorUpcoming.body.map((c: any) => c.id)).toEqual([confirmedClass.id]);

    const detailForbidden = await request(app)
      .get(`/api/v1/classes/${confirmedClass.id}`)
      .set("Authorization", `Bearer ${otherStudentToken}`);
    expect(detailForbidden.status).toBe(403);
  });

  it("endpoints premium exponen contrato completo para UX sin inferencias", async () => {
    const { instructor, token: instructorToken } = await createInstructor();
    const { student, token: studentToken } = await createStudent();
    const { token: otherStudentToken } = await createStudent();

    const startsAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    const booking = await prisma.drivingClass.create({
      data: {
        studentId: student.id,
        instructorId: instructor.id,
        date: startsAt,
        duration: 90,
        status: BookingStatus.PENDING_PAYMENT,
        amount: 15000,
        currency: "ARS",
      },
    });

    await prisma.scheduleSlot.create({
      data: {
        instructorId: instructor.id,
        startTime: startsAt,
        endTime: new Date(startsAt.getTime() + 90 * 60 * 1000),
        status: SlotStatus.HELD,
        heldUntil: new Date(Date.now() + 5 * 60 * 1000),
        drivingClassId: booking.id,
      },
    });

    await prisma.payment.create({
      data: {
        amount: 15000,
        status: "pending",
        paymentMethod: "pending",
        provider: "mercadopago",
        drivingClassId: booking.id,
      },
    });

    const studentUpcoming = await request(app)
      .get("/api/v1/classes/student/upcoming")
      .set("Authorization", `Bearer ${studentToken}`);
    expect(studentUpcoming.status).toBe(200);
    expect(studentUpcoming.body).toHaveLength(1);
    expect(studentUpcoming.body[0]).toEqual(
      expect.objectContaining({
        id: booking.id,
        status: "PENDING_PAYMENT",
        paymentStatus: "pending",
        slotStatus: "HELD",
        canCancel: expect.any(Boolean),
        canReschedule: false,
        cancelDeadline: expect.any(String),
        rescheduleDeadline: expect.any(String),
        nextRecommendedAction: "COMPLETE_PAYMENT",
        policySummary: expect.objectContaining({
          cancelWindowHours: 6,
          rescheduleWindowHours: 12,
        }),
        priceSummary: expect.objectContaining({
          amount: 15000,
          currency: "ARS",
        }),
        durationMinutes: 90,
        startsAt: expect.any(String),
        endsAt: expect.any(String),
        instructorSnapshot: expect.objectContaining({
          id: instructor.id,
        }),
        studentSnapshot: expect.objectContaining({
          id: student.id,
        }),
        legacy: expect.objectContaining({
          instructorId: instructor.id,
          studentId: student.id,
        }),
      })
    );
    expect(studentUpcoming.body[0].location).toHaveProperty("addressText");
    expect(studentUpcoming.body[0].location).toHaveProperty("zoneLabel");

    const studentDetail = await request(app)
      .get(`/api/v1/classes/student/${booking.id}`)
      .set("Authorization", `Bearer ${studentToken}`);
    expect(studentDetail.status).toBe(200);
    expect(studentDetail.body.id).toBe(booking.id);

    const instructorUpcoming = await request(app)
      .get("/api/v1/classes/instructor/upcoming")
      .set("Authorization", `Bearer ${instructorToken}`);
    expect(instructorUpcoming.status).toBe(200);
    expect(instructorUpcoming.body).toHaveLength(1);
    expect(instructorUpcoming.body[0].studentSnapshot.id).toBe(student.id);

    const forbiddenRole = await request(app)
      .get("/api/v1/classes/instructor/upcoming")
      .set("Authorization", `Bearer ${studentToken}`);
    expect(forbiddenRole.status).toBe(403);

    const forbiddenDetail = await request(app)
      .get(`/api/v1/classes/student/${booking.id}`)
      .set("Authorization", `Bearer ${otherStudentToken}`);
    expect(forbiddenDetail.status).toBe(403);
  });

  it("alumno con rol STUDENT pero sin fila Student: premium upcoming/history 200 [] y autocrea Student", async () => {
    const id = nextSeq();
    const hashedPassword = await bcrypt.hash("password123", 10);
    const email = `missing_student_row_${id}@example.com`;
    const user = await prisma.user.create({
      data: {
        name: "Alumno",
        surname: "SinFila",
        email,
        dni: `6000${id}`,
        password: hashedPassword,
        role: "STUDENT",
        birthDate: new Date("2000-01-01"),
        emailVerifiedAt: new Date(),
        isActive: true,
      },
    });

    expect(await prisma.student.findUnique({ where: { userId: user.id } })).toBeNull();

    const loginRes = await request(app).post("/api/v1/auth/login").send({
      email,
      password: "password123",
    });
    expect(loginRes.status).toBe(200);
    const token = loginRes.body.accessToken as string;

    const upcoming = await request(app)
      .get("/api/v1/classes/student/upcoming")
      .set("Authorization", `Bearer ${token}`);
    expect(upcoming.status).toBe(200);
    expect(Array.isArray(upcoming.body)).toBe(true);
    expect(upcoming.body).toHaveLength(0);

    const history = await request(app)
      .get("/api/v1/classes/student/history")
      .set("Authorization", `Bearer ${token}`);
    expect(history.status).toBe(200);
    expect(history.body).toHaveLength(0);

    const created = await prisma.student.findUnique({ where: { userId: user.id } });
    expect(created).not.toBeNull();
  });
});
