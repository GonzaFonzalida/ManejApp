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