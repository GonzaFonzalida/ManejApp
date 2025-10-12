import SessionRepository from "./SessionRepository";
import { PrismaClient } from "@prisma/client";
import { prisma as prismaConfig } from "@config/prismaClient";
export default class PrismaSessionRepository implements SessionRepository {
  private prisma = prismaConfig
  constructor() {}

  async create(params: {
    userId: number;
    refreshHash: string;
    userAgent?: string;
    ip?: string;
    expiresAt: Date;
  }) {
    return await this.prisma.session.create({ data: params });
  }

  async deleteSession(id: string) {
    return await this.prisma.session.delete({
      where: { id },
    });
  }

  async deleteSessionsByUser(userId: number): Promise<{ count: number }> {
    return await this.prisma.session.deleteMany({
      where: { userId },
    });
  }


  async findById(id: string) {
    return await this.prisma.session.findUnique({ where: { id } });
  }

  async findValidByUser(userId: number) {
    return await this.prisma.session.findMany({
      where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
      orderBy: { createdAt: "desc" },
    });
  }

  async revokeById(id: string) {
    return await this.prisma.session.update({ where: { id }, data: { revokedAt: new Date() } }).then(() => {});
  }

  async revokeAllByUser(userId: number) {
    return await this.prisma.session.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    }).then(() => {});
  }

  async findByHash(refreshHash: string) {
    return await this.prisma.session.findFirst({
      where: { refreshHash, revokedAt: null, expiresAt: { gt: new Date() } },
    });

  
  }
}