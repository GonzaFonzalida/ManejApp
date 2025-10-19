import { prisma } from '@config/prismaClient';
import { INotificationTokenRepository } from './NotificationTokenRepository';

export class PrismaNotificationTokenRepository implements INotificationTokenRepository {
  constructor() {}

  async findByUserId(userId: number) {
    return prisma.notificationToken.findUnique({
      where: { userId },
    });
  }

  async create(data: { userId: number; token: string }) {
    return prisma.notificationToken.create({
      data,
    });
  }

  async updateByUserId(userId: number, token: string) {
    return prisma.notificationToken.upsert({
      where: { userId },
      update: { token },
      create: { userId, token },
    });
  }

  async deleteByUserId(userId: number) {
    await prisma.notificationToken.delete({
      where: { userId },
    });
  }

  async findAll() {
    return prisma.notificationToken.findMany();
  }
}