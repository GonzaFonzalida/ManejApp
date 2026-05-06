import request from "supertest";
import bcrypt from "bcryptjs";
import { randomUUID } from "crypto";
import { buildApp } from "../../src/app";
import { prisma } from "../../src/config/prismaClient";
import { clearDatabase } from "../helpers/db-cleaner";
import { Role } from "@prisma/client";

const app = buildApp();

async function seedUser(role: Role, label: string) {
  const suffix = randomUUID().replace(/-/g, "").slice(0, 16);
  const hashedPassword = await bcrypt.hash("password123", 10);
  const email = `${label}_${suffix}@example.com`;
  const user = await prisma.user.create({
    data: {
      name: label,
      surname: "Msg",
      email,
      dni: `dni${suffix}`,
      password: hashedPassword,
      role,
      birthDate: new Date("1995-05-05"),
      emailVerifiedAt: new Date(),
      isActive: true,
    },
  });
  if (role === Role.STUDENT) {
    await prisma.student.create({ data: { userId: user.id } });
  }
  const loginRes = await request(app).post("/api/v1/auth/login").send({
    email,
    password: "password123",
  });
  return { user, token: loginRes.body.accessToken as string };
}

describe("Messages HTTP integration", () => {
  beforeEach(async () => {
    await clearDatabase();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it("POST /api/v1/messages/send crea conversación y mensaje", async () => {
    const a = await seedUser(Role.STUDENT, "alice");
    const b = await seedUser(Role.STUDENT, "bob");

    const send = await request(app)
      .post("/api/v1/messages/send")
      .set("Authorization", `Bearer ${a.token}`)
      .send({ receiverId: b.user.id, content: "Hola desde test" });

    expect(send.status).toBe(201);
    expect(send.body.success).toBe(true);
    expect(send.body.data?.content).toBe("Hola desde test");
    expect(send.body.data?.senderId).toBe(a.user.id);
  });

  it("GET /api/v1/messages/conversations lista conversaciones del usuario", async () => {
    const a = await seedUser(Role.STUDENT, "carol");
    const b = await seedUser(Role.STUDENT, "dave");

    await request(app)
      .post("/api/v1/messages/send")
      .set("Authorization", `Bearer ${a.token}`)
      .send({ receiverId: b.user.id, content: "Ping" });

    const list = await request(app)
      .get("/api/v1/messages/conversations")
      .set("Authorization", `Bearer ${a.token}`);

    expect(list.status).toBe(200);
    expect(list.body.success).toBe(true);
    expect(Array.isArray(list.body.data)).toBe(true);
    expect(list.body.data.length).toBeGreaterThanOrEqual(1);
  });

  it("GET /api/v1/messages/conversations/:id/messages devuelve mensajes", async () => {
    const a = await seedUser(Role.STUDENT, "erin");
    const b = await seedUser(Role.STUDENT, "frank");

    const send = await request(app)
      .post("/api/v1/messages/send")
      .set("Authorization", `Bearer ${a.token}`)
      .send({ receiverId: b.user.id, content: "Mensaje único" });
    const conversationId = send.body.data?.conversationId as number;
    expect(conversationId).toBeTruthy();

    const msgs = await request(app)
      .get(`/api/v1/messages/conversations/${conversationId}/messages`)
      .set("Authorization", `Bearer ${a.token}`);

    expect(msgs.status).toBe(200);
    expect(msgs.body.success).toBe(true);
    expect(Array.isArray(msgs.body.data)).toBe(true);
    expect(msgs.body.data.some((m: { content: string }) => m.content === "Mensaje único")).toBe(true);
  });

  it("sin token, POST /send responde 401", async () => {
    const res = await request(app)
      .post("/api/v1/messages/send")
      .send({ receiverId: 1, content: "x" });
    expect(res.status).toBe(401);
  });
});
