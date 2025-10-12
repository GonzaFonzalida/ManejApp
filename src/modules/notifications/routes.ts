import { Router } from 'express';
import { NotificationController } from './controller';
import { validate } from '@shared/middlewares/zod/validateBody';
import { sendToUserSchema, sendToRoleSchema, broadcastSchema, registerTokenSchema } from './schemas';

export class NotificationRoutes {
  private router: Router;

  constructor(private controller: NotificationController) {
    this.router = Router();
    this.initializeRoutes();
  }

  private initializeRoutes() {
    this.router.post(
      '/send-to-user',
      validate(sendToUserSchema),
      this.controller.sendToUser.bind(this.controller)
    );

    this.router.post(
      '/send-to-role',
      validate(sendToRoleSchema),
      this.controller.sendToRole.bind(this.controller)
    );

    this.router.post(
      '/broadcast',
      validate(broadcastSchema),
      this.controller.broadcast.bind(this.controller)
    );

    this.router.post(
      '/token',
      validate(registerTokenSchema),
      this.controller.registerToken.bind(this.controller)
    );
  }

  getRouter(): Router {
    return this.router;
  }
}