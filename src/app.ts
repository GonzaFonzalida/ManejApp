import express from "express";
const swaggerJSDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
import diContainer from "@shared/DiContainer/container";
import errorHandler from "@middlewares/errorMiddleware";
import notFoundHandler from "@middlewares/notFoundMiddleware";
import {
  requestLoggerMiddleware,
  errorLoggerMiddleware,
  performanceLoggerMiddleware
} from "@logging/middleware/requestLogger";
import { logger } from "@logging/LoggerConfig";

import UserRouter from "@users/user.routes";
import UserController from "@users/user.controller";

import InstructorController from "@instructors/instructor.controller";
import InstructorRouter from "@instructors/instructor.routes";

import AuthController from "@auth/auth.controller";
import buildAuthRouter from "@auth/auth.routes";
import permissionsRouter from "@permissions/permissions.routes";
import carRouters from "@cars/cars.routes";
import DrivingClassRouter from "@drivingClass/routes";
import { DrivingClassController } from "@drivingClass/controller";

import PaymentController from "@payments/payment.controller";
import PaymentRouter from "@payments/payment.routes";

import { ScheduleController } from "@schedule/schedule.controller";
import { ScheduleRouter } from "@schedule/schedule.routes";

import { NotificationController } from "@notifications/controller";
import { NotificationRoutes } from "@notifications/routes";

export const buildApp = () => {

    const userController = diContainer.resolve<UserController>("userController");
    const userRouter = new UserRouter(userController).init();

    const instructorController = diContainer.resolve<InstructorController>("instructorController");
    const instructorRouter = new InstructorRouter(instructorController).init();

    const authController = diContainer.resolve<AuthController>("authController");
    const authRouter = buildAuthRouter(authController);

    const drivingClassController = diContainer.resolve<DrivingClassController>("DrivingClassController");
    const drivingClassRouter = new DrivingClassRouter(drivingClassController).init();

    const paymentController = diContainer.resolve<PaymentController>("paymentController");
    const paymentRouter = new PaymentRouter(paymentController).init();

    const scheduleController = diContainer.resolve<ScheduleController>("scheduleController");
    const scheduleRouter = new ScheduleRouter(scheduleController).init();

    const notificationController = diContainer.resolve<NotificationController>("notificationController");
    const notificationRouter = new NotificationRoutes(notificationController).getRouter();

    const app = express();

    // Swagger configuration
    const swaggerOptions = {
      definition: {
        openapi: '3.0.0',
        info: {
          title: 'ManejApp API',
          version: '1.0.0',
          description: 'API documentation for ManejApp - Driving School Management System',
        },
        servers: [
          {
            url: 'http://localhost:3000',
            description: 'Development server',
          },
        ],
        components: {
          securitySchemes: {
            bearerAuth: {
              type: 'http',
              scheme: 'bearer',
              bearerFormat: 'JWT',
            },
          },
        },
        security: [
          {
            bearerAuth: [],
          },
        ],
      },
      apis: ['./src/**/*.ts'], // Paths to files containing OpenAPI definitions
    };

    const specs = swaggerJSDoc(swaggerOptions);

    // Logging middlewares (should be first)
    app.use(requestLoggerMiddleware);
    app.use(performanceLoggerMiddleware(2000)); // Log requests slower than 2 seconds

    app.use(express.json());

    // Swagger UI
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

    app.use("/users", userRouter);
    app.use("/instructors", instructorRouter);
    app.use("/permissions", permissionsRouter);
    app.use("/cars", carRouters);
    app.use("/auth", authRouter);
    app.use("/classes", drivingClassRouter);
    app.use("/payments", paymentRouter);
    app.use("/schedule", scheduleRouter);
    app.use("/notifications", notificationRouter);
    //modulos
    // app.use("/permissions"); // ya registrado arriba
    // app.use("/admin");
    // app.use("/cars") // ya registrado arriba

    app.use(notFoundHandler);
    app.use(errorLoggerMiddleware); // Log errors before handling them
    app.use(errorHandler);

    // Log application startup
    logger.info('ManejApp initialized successfully', {
      module: 'app',
      function: 'buildApp',
    }, {
      routes: [
        '/users',
        '/instructors',
        '/permissions',
        '/cars',
        '/auth',
        '/classes',
        '/payments',
        '/schedule',
        '/notifications'
      ]
    });

    return app;
}


