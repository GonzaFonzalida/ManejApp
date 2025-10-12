import express from "express";
const swaggerJSDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
import diContainer from "./shared/DiContainer/container";
import errorHandler from "./shared/middlewares/errorMiddleware";
import notFoundHandler from "./shared/middlewares/notFoundMiddleware";
import {
  requestLoggerMiddleware,
  errorLoggerMiddleware,
  performanceLoggerMiddleware
} from "./shared/logging/middleware/requestLogger";
import { logger } from "./shared/logging/LoggerConfig";

import UserRouter from "./users/user.routes";
import UserController from "./users/user.controller";

import InstructorController from "./modules/instructors/instructor.controller";
import InstructorRouter from "./modules/instructors/instructor.routes";

import AuthController from "src/modules/auth/auth.controller";
import buildAuthRouter from "src/modules/auth/auth.routes";
import permissionsRouter from "./modules/permissions/permissions.routes";
import carRouters from "./modules/cars/cars.routes";
import DrivingClassRouter from "./modules/drivingClass/routes";
import { DrivingClassController } from "./modules/drivingClass/controller";

import PaymentController from "./modules/payments/payment.controller";
import PaymentRouter from "./modules/payments/payment.routes";

import { ScheduleController } from "./modules/schedule/schedule.controller";
import { ScheduleRouter } from "./modules/schedule/schedule.routes";

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
        '/schedule'
      ]
    });

    return app;
}


