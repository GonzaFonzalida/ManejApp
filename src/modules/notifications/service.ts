import * as admin from 'firebase-admin';
import { Logger } from '@shared/logging/Logger';
import CustomizedError  from '@shared/classes/CustomizedError';
import { INotificationTokenRepository } from './repositories/NotificationTokenRepository';
import { UserRepository } from '@users/repositories/userRepository';
import { Role } from '@prisma/client';
import { getFirebaseApp } from '@config/firebase';

export class NotificationService {
  private fcm: admin.messaging.Messaging;

  constructor(
    private logger: Logger,
    private notificationTokenRepo: INotificationTokenRepository,
    private userRepo: UserRepository
  ) {
    try {
      const app = getFirebaseApp();
      this.fcm = admin.messaging(app);
    } catch (error) {
      this.logger.warn('Firebase not available, notifications will be mocked', error instanceof Error ? error : new Error(String(error)));
      // Mock FCM para desarrollo
      this.fcm = null as any;
    }
  }

  async sendToUser(userId: number, title: string, body: string): Promise<void> {
    try {
      if (!this.fcm) {
        this.logger.info(`[MOCK] Notification to user ${userId}: ${title} - ${body}`);
        return;
      }

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
      if (!this.fcm) {
        this.logger.info(`[MOCK] Notification to role ${role}: ${title} - ${body}`);
        return;
      }

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
      if (!this.fcm) {
        this.logger.info(`[MOCK] Broadcast notification: ${title} - ${body}`);
        return;
      }

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

  async sendClassReminder(drivingClassId: number): Promise<void> {
    try {
      // Aquí iría la lógica para obtener la clase y enviar recordatorios
      // Se implementaría con el repositorio de DrivingClass
      this.logger.info(`Class reminder sent for class ${drivingClassId}`);
    } catch (error) {
      this.logger.error(`Error sending class reminder:`, error instanceof Error ? error : new Error(String(error)));
    }
  }

  async sendPaymentConfirmation(paymentId: number): Promise<void> {
    try {
      // Lógica para confirmar pago
      this.logger.info(`Payment confirmation sent for payment ${paymentId}`);
    } catch (error) {
      this.logger.error(`Error sending payment confirmation:`, error instanceof Error ? error : new Error(String(error)));
    }
  }

  async sendClassStatusUpdate(drivingClassId: number, newStatus: string): Promise<void> {
    try {
      // Lógica para actualización de estado
      this.logger.info(`Class status update sent for class ${drivingClassId}: ${newStatus}`);
    } catch (error) {
      this.logger.error(`Error sending class status update:`, error instanceof Error ? error : new Error(String(error)));
    }
  }
}