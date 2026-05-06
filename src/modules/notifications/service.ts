import * as admin from 'firebase-admin';
import { Logger } from '@shared/logging/Logger';
import CustomizedError  from '@shared/classes/CustomizedError';
import { INotificationTokenRepository } from './repositories/NotificationTokenRepository';
import { UserRepository } from '@users/repositories/userRepository';
import { Role } from '@prisma/client';
import { getFirebaseApp } from '@config/firebase';
import EmailService from '@shared/services/EmailService';

export class NotificationService {
  private fcm: admin.messaging.Messaging;
  private emailService: EmailService;

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

    this.emailService = new EmailService();
  }

  /**
   * Solo push FCM (sin email). Para eventos de producto: respeta `pushNotifications` del usuario.
   * `data` se envía en el payload para deep linking en la app (valores string).
   */
  async sendPushToUser(
    userId: number,
    title: string,
    body: string,
    data?: Record<string, string>
  ): Promise<void> {
    try {
      const user = await this.userRepo.findUser(userId.toString());
      if (!user) {
        this.logger.warn(`sendPushToUser: user ${userId} not found`);
        return;
      }
      const userPrefs = user as any;
      if (userPrefs.pushNotifications === false) {
        return;
      }
      if (!this.fcm) {
        this.logger.info(`[MOCK] Push only → user ${userId}: ${title} — ${body} data=${JSON.stringify(data ?? {})}`);
        return;
      }
      const tokenRecord = await this.notificationTokenRepo.findByUserId(userId);
      if (!tokenRecord) {
        this.logger.warn(`sendPushToUser: no FCM token for user ${userId}`);
        return;
      }
      const dataPayload: Record<string, string> = {};
      if (data) {
        for (const [k, v] of Object.entries(data)) {
          dataPayload[k] = v != null ? String(v) : '';
        }
      }
      const message: admin.messaging.Message = {
        token: tokenRecord.token,
        notification: { title, body },
        android: { priority: 'high' },
        apns: {
          payload: { aps: { sound: 'default' } },
        },
      };
      if (Object.keys(dataPayload).length > 0) {
        message.data = dataPayload;
      }
      const response = await this.fcm.send(message);
      this.logger.info(`sendPushToUser ok user=${userId} ${response}`);
    } catch (error) {
      this.logger.error(
        `sendPushToUser failed user=${userId}:`,
        error instanceof Error ? error : new Error(String(error))
      );
    }
  }

  async sendToUser(userId: number, title: string, body: string, type: 'info' | 'success' | 'warning' | 'error' = 'info'): Promise<void> {
    try {
      // Obtener preferencias del usuario
      const user = await this.userRepo.findUser(userId.toString());
      if (!user) {
        this.logger.warn(`User ${userId} not found`);
        return;
      }

      const userPrefs = (user as any);

      // Enviar push notification si está habilitado
      if (userPrefs.pushNotifications !== false) {
        if (!this.fcm) {
          this.logger.info(`[MOCK] Push notification to user ${userId}: ${title} - ${body}`);
        } else {
          const tokenRecord = await this.notificationTokenRepo.findByUserId(userId);
          if (tokenRecord) {
            const message = {
              token: tokenRecord.token,
              notification: {
                title,
                body,
              },
            };

            const response = await this.fcm.send(message);
            this.logger.info(`Push notification sent to user ${userId}: ${response}`);
          } else {
            this.logger.warn(`No FCM token found for user ${userId}`);
          }
        }
      }

      // Enviar email notification si está habilitado
      if (userPrefs.emailNotifications !== false) {
        try {
          await this.emailService.sendUserNotification(user.email, title, body, type);
          this.logger.info(`Email notification sent to user ${userId}: ${title}`);
        } catch (emailError) {
          this.logger.error(`Error sending email notification to user ${userId}:`, emailError instanceof Error ? emailError : new Error(String(emailError)));
        }
      }

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
      // Por ahora, mock
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

  async sendClassReminderToUser(userId: number, classInfo: { date: string, instructor: string, location?: string }): Promise<void> {
    try {
      const user = await this.userRepo.findUser(userId.toString());
      if (!user) return;

      const userPrefs = (user as any);

      if (userPrefs.emailNotifications !== false) {
        await this.emailService.sendClassReminder(user.email, classInfo);
        this.logger.info(`Class reminder email sent to user ${userId}`);
      }

      if (userPrefs.pushNotifications !== false) {
        await this.sendToUser(userId, 'Recordatorio de Clase', `Tu clase es el ${new Date(classInfo.date).toLocaleString()} con ${classInfo.instructor}`);
      }
    } catch (error) {
      this.logger.error(`Error sending class reminder to user ${userId}:`, error instanceof Error ? error : new Error(String(error)));
    }
  }

  async sendPaymentConfirmationToUser(userId: number, paymentInfo: { amount: number, classDate: string, instructor: string }): Promise<void> {
    try {
      const user = await this.userRepo.findUser(userId.toString());
      if (!user) return;

      const userPrefs = (user as any);

      if (userPrefs.emailNotifications !== false) {
        await this.emailService.sendPaymentConfirmation(user.email, paymentInfo);
        this.logger.info(`Payment confirmation email sent to user ${userId}`);
      }

      if (userPrefs.pushNotifications !== false) {
        await this.sendToUser(userId, 'Pago Confirmado', `Tu pago de $${paymentInfo.amount} ha sido confirmado`);
      }
    } catch (error) {
      this.logger.error(`Error sending payment confirmation to user ${userId}:`, error instanceof Error ? error : new Error(String(error)));
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