import SessionRepository from "./SessionRepository";
import { PrismaClient } from "@prisma/client";
import { prisma as prismaConfig } from "@config/prismaClient";
export default class PrismaSessionRepository implements SessionRepository {
  private prisma = prismaConfig
  constructor() {}

  create(params: {
    userId: number;
    refreshHash: string;
    userAgent?: string;
    ip?: string;
    expiresAt: Date;
  }) {
    return this.prisma.session.create({ data: params });
  }

  findById(id: string) {
    return this.prisma.session.findUnique({ where: { id } });
  }

  findValidByUser(userId: number) {
    return this.prisma.session.findMany({
      where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
      orderBy: { createdAt: "desc" },
    });
  }

  revokeById(id: string) {
    return this.prisma.session.update({ where: { id }, data: { revokedAt: new Date() } }).then(() => {});
  }

  revokeAllByUser(userId: number) {
    return this.prisma.session.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    }).then(() => {});
  }

  findByHash(refreshHash: string) {
    return this.prisma.session.findFirst({
      where: { refreshHash, revokedAt: null, expiresAt: { gt: new Date() } },
    });
  }
}