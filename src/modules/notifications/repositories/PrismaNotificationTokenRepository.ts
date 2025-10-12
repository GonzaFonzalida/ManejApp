import { PrismaClient } from '@prisma/client';
import { INotificationTokenRepository } from './NotificationTokenRepository';

export class PrismaNotificationTokenRepository implements INotificationTokenRepository {
  constructor(private prisma: PrismaClient) {}

  async findByUserId(userId: number) {
    return this.prisma.notificationToken.findUnique({
      where: { userId },
    });
  }

  async create(data: { userId: number; token: string }) {
    return this.prisma.notificationToken.create({
      data,
    });
  }

  async updateByUserId(userId: number, token: string) {
    return this.prisma.notificationToken.upsert({
      where: { userId },
      update: { token, updatedAt: new Date() },
      create: { userId, token },
    });
  }

  async deleteByUserId(userId: number) {
    await this.prisma.notificationToken.delete({
      where: { userId },
    });
  }

  async findAll() {
    return this.prisma.notificationToken.findMany();
  }
}