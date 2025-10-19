import { Request, Response } from 'express';
import { NotificationService } from './service';
import { AuthenticatedRequest } from '@shared/types/AuthenticatedRequest';
import  CustomizedError  from '@shared/classes/CustomizedError';
import { Logger } from '@shared/logging';

export class NotificationController {
  constructor(
    private notificationService: NotificationService,
    private logger: Logger
  ) {}

  /**
   * @swagger
   * /notifications/send-to-user:
   *   post:
   *     summary: Send notification to specific user
   *     tags: [Notifications]
   *     security:
   *       - bearerAuth: []
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - userId
   *               - title
   *               - body
   *             properties:
   *               userId:
   *                 type: integer
   *                 minimum: 1
   *               title:
   *                 type: string
   *                 minLength: 1
   *                 maxLength: 100
   *               body:
   *                 type: string
   *                 minLength: 1
   *                 maxLength: 500
   *     responses:
   *       200:
   *         description: Notification sent successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 message:
   *                   type: string
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  async sendToUser(req: AuthenticatedRequest, res: Response) {
    try {
      const { userId, title, body } = req.body;
      await this.notificationService.sendToUser(userId, title, body);
      res.status(200).json({ message: 'Notification sent successfully' });
    } catch (error) {
      this.logger.error('Error in sendToUser:', error instanceof Error ? error : new Error(String(error)));
      if (error instanceof CustomizedError) {
        res.status(error.statusCode).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  }

  /**
   * @swagger
   * /notifications/send-to-role:
   *   post:
   *     summary: Send notification to all users with specific role
   *     tags: [Notifications]
   *     security:
   *       - bearerAuth: []
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - role
   *               - title
   *               - body
   *             properties:
   *               role:
   *                 type: string
   *                 enum: [STUDENT, INSTRUCTOR, ADMIN]
   *               title:
   *                 type: string
   *                 minLength: 1
   *                 maxLength: 100
   *               body:
   *                 type: string
   *                 minLength: 1
   *                 maxLength: 500
   *     responses:
   *       200:
   *         description: Notification sent successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 message:
   *                   type: string
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  async sendToRole(req: AuthenticatedRequest, res: Response) {
    try {
      const { role, title, body } = req.body;
      await this.notificationService.sendToRole(role, title, body);
      res.status(200).json({ message: 'Notification sent successfully' });
    } catch (error) {
      this.logger.error('Error in sendToRole:', error instanceof Error ? error : new Error(String(error)));
      if (error instanceof CustomizedError) {
        res.status(error.statusCode).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  }

  /**
   * @swagger
   * /notifications/broadcast:
   *   post:
   *     summary: Send broadcast notification to all users
   *     tags: [Notifications]
   *     security:
   *       - bearerAuth: []
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - title
   *               - body
   *             properties:
   *               title:
   *                 type: string
   *                 minLength: 1
   *                 maxLength: 100
   *               body:
   *                 type: string
   *                 minLength: 1
   *                 maxLength: 500
   *     responses:
   *       200:
   *         description: Broadcast sent successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 message:
   *                   type: string
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  async broadcast(req: AuthenticatedRequest, res: Response) {
    try {
      const { title, body } = req.body;
      await this.notificationService.broadcast(title, body);
      res.status(200).json({ message: 'Broadcast sent successfully' });
    } catch (error) {
      this.logger.error('Error in broadcast:', error instanceof Error ? error : new Error(String(error)));
      if (error instanceof CustomizedError) {
        res.status(error.statusCode).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  }

  /**
   * @swagger
   * /notifications/token:
   *   post:
   *     summary: Register FCM token for push notifications
   *     tags: [Notifications]
   *     security:
   *       - bearerAuth: []
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - token
   *             properties:
   *               token:
   *                 type: string
   *                 minLength: 10
   *                 description: Firebase Cloud Messaging token
   *     responses:
   *       200:
   *         description: Token registered successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 message:
   *                   type: string
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  async registerToken(req: AuthenticatedRequest, res: Response) {
    try {
      const { token } = req.body;
      const userId = req.user!.id; // Asumiendo que AuthenticatedRequest tiene user
      await this.notificationService.registerToken(userId, token);
      res.status(200).json({ message: 'Token registered successfully' });
    } catch (error) {
      this.logger.error('Error in registerToken:', error instanceof Error ? error : new Error(String(error)));
      if (error instanceof CustomizedError) {
        res.status(error.statusCode).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Internal server error' });
      }
    }
  }
}