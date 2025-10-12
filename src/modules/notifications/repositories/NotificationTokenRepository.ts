import { NotificationToken } from '@prisma/client';

export interface INotificationTokenRepository {
  findByUserId(userId: number): Promise<NotificationToken | null>;
  create(data: { userId: number; token: string }): Promise<NotificationToken>;
  updateByUserId(userId: number, token: string): Promise<NotificationToken>;
  deleteByUserId(userId: number): Promise<void>;
  findAll(): Promise<NotificationToken[]>;
}