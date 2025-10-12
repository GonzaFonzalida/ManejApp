import * as admin from 'firebase-admin';
import { Logger } from '@shared/logging/Logger';
import CustomizedError  from '@shared/classes/CustomizedError';
import { INotificationTokenRepository } from './repositories/NotificationTokenRepository';
import { UserRepository } from 'src/users/repositories/userRepository';
import { Role } from '@prisma/client';

export class NotificationService {
  private fcm: admin.messaging.Messaging;

  constructor(
    private logger: Logger,
    private notificationTokenRepo: INotificationTokenRepository,
    private userRepo: UserRepository
  ) {
    // Inicializar FCM
    if (!admin.apps.length) {
      // Asumir que las credenciales están en config
      // TODO: Configurar credenciales
      this.fcm = admin.messaging();
    } else {
      this.fcm = admin.messaging();
    }
  }

  async sendToUser(userId: number, title: string, body: string): Promise<void> {
    try {
      const tokenRecord = await this.notificationTokenRepo.findByUserId(userId);
      if (!tokenRecord) {
        this.logger.warn(`No FCM token found for user ${userId}`);
        return;
      }

      const message = {
        token: tokenRecord.token,
        notification: {
          title,
          body,
        },
      };

      const response = await this.fcm.send(message);
      this.logger.info(`Notification sent to user ${userId}: ${response}`);
    } catch (error) {
      this.logger.error(`Error sending notification to user ${userId}:`, error instanceof Error ? error : new Error(String(error)));
      throw new CustomizedError('Failed to send notification', 500);
    }
  }

  async sendToRole(role: Role, title: string, body: string): Promise<void> {
    try {
      // Obtener usuarios por role
      const users = await this.userRepo.findByRole(role.toString());
      const tokens: string[] = [];

      for (const user of users) {
        const tokenRecord = await this.notificationTokenRepo.findByUserId(user.id);
        if (tokenRecord) {
          tokens.push(tokenRecord.token);
        }
      }

      if (tokens.length === 0) {
        this.logger.warn(`No FCM tokens found for role ${role}`);
        return;
      }

      const messages = tokens.map(token => ({
        token,
        notification: {
          title,
          body,
        },
      }));

      const response = await this.fcm.sendEach(messages);
      this.logger.info(`Notification sent to role ${role}: ${response.successCount} success, ${response.failureCount} failures`);
    } catch (error) {
      this.logger.error(`Error sending notification to role ${role}:`, error instanceof Error ? error : new Error(String(error)));
      throw new CustomizedError('Failed to send notification', 500);
    }
  }

  async broadcast(title: string, body: string): Promise<void> {
    try {
      // Obtener todos los tokens
      const tokenRecords = await this.notificationTokenRepo.findAll();
      const tokens = tokenRecords.map(r => r.token);

      if (tokens.length === 0) {
        this.logger.warn('No FCM tokens found for broadcast');
        return;
      }

      const messages = tokens.map(token => ({
        token,
        notification: {
          title,
          body,
        },
      }));

      const response = await this.fcm.sendEach(messages);
      this.logger.info(`Broadcast notification sent: ${response.successCount} success, ${response.failureCount} failures`);
    } catch (error) {
      this.logger.error('Error sending broadcast notification:', error instanceof Error ? error : new Error(String(error)));
      throw new CustomizedError('Failed to send notification', 500);
    }
  }

  async registerToken(userId: number, token: string): Promise<void> {
    try {
      await this.notificationTokenRepo.updateByUserId(userId, token);
      this.logger.info(`FCM token registered for user ${userId}`);
    } catch (error) {
      this.logger.error(`Error registering FCM token for user ${userId}:`, error instanceof Error ? error : new Error(String(error)));
      throw new CustomizedError('Failed to register token', 500);
    }
  }
}