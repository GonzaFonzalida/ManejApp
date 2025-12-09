import express from "express";
const swaggerJSDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
import cors from 'cors';
import diContainer from "@shared/DiContainer/container";
import errorHandler from "@middlewares/errorMiddleware";
import notFoundHandler from "@middlewares/notFoundMiddleware";
import {
  requestLoggerMiddleware,
  errorLoggerMiddleware,
  performanceLoggerMiddleware
} from "@logging/middleware/requestLogger";
import { logger } from "@logging/LoggerConfig";
import { 
  generalRateLimit, 
  corsOptions, 
  helmetConfig 
} from "@middlewares/security";
import { sanitizeInput } from "@middlewares/validation";
import { healthCheck } from "@middlewares/healthCheck";
import { preventSQLInjection, preventXSS } from "@middlewares/advancedValidation";

import UserRouter from "@users/user.routes";
import UserController from "@users/user.controller";

import InstructorController from "@instructors/instructor.controller";
import InstructorRouter from "@instructors/instructor.routes";

import AuthController from "@auth/auth.controller";
import buildAuthRouter from "@auth/auth.routes";
import permissionsRouter from "@permissions/permissions.routes";
import improvedCarRoutes from "@cars/improved-cars.routes";
import DrivingClassRouter from "@drivingClass/routes";
import { DrivingClassController } from "@drivingClass/controller";

import { functionalPaymentRoutes, webhookRouter } from "@payments/functional-payment.routes";
import commissionRoutes from "@payments/commission.routes";

import { ScheduleController } from "@schedule/schedule.controller";
import { ScheduleRouter } from "@schedule/schedule.routes";

import { NotificationController } from "@notifications/controller";
import { NotificationRoutes } from "@notifications/routes";

import MessageController from "./modules/messages/messages.controller";
import messageRoutes from "./modules/messages/messages.routes";

import adminRoutes from "./modules/admin/admin.routes";
import SchedulerService from "./shared/services/SchedulerService";

export const buildApp = () => {

    const userController = diContainer.resolve<UserController>("userController");
    const userRouter = new UserRouter(userController).init();

    const instructorController = diContainer.resolve<InstructorController>("instructorController");
    const instructorRouter = new InstructorRouter(instructorController).init();

    const authController = diContainer.resolve<AuthController>("authController");
    const authRouter = buildAuthRouter(authController);

    const drivingClassController = diContainer.resolve<DrivingClassController>("DrivingClassController");
    const drivingClassRouter = new DrivingClassRouter(drivingClassController).init();

    // Payment routes are now self-contained

    const scheduleController = diContainer.resolve<ScheduleController>("scheduleController");
    const scheduleRouter = new ScheduleRouter(scheduleController).init();

    const notificationController = diContainer.resolve<NotificationController>("notificationController");
    const notificationRouter = new NotificationRoutes(notificationController).getRouter();

    const messageController = diContainer.resolve<MessageController>("messageController");

    const app = express();

    // Trust proxy for production (behind reverse proxy/load balancer)
    app.set('trust proxy', true);

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
            url: 'http://localhost:3000/api/v1',
            description: 'Development server v1',
          },
          {
            url: 'https://api.manejapp.com/api/v1',
            description: 'Production server v1',
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
      tags: [
        {
          name: 'Authentication',
          description: 'Authentication and authorization endpoints'
        },
        {
          name: 'Users',
          description: 'User management endpoints'
        },
        {
          name: 'Security',
          description: 'Security and monitoring endpoints'
        }
      ]
    };

    const specs = swaggerJSDoc(swaggerOptions);

    // Security middlewares (should be first)
    app.use(helmetConfig);
    app.use(cors(corsOptions));
    app.use(generalRateLimit);
    app.use(preventSQLInjection);
    app.use(preventXSS);
    app.use(sanitizeInput);
    
    // Logging middlewares
    app.use(requestLoggerMiddleware);
    app.use(performanceLoggerMiddleware(2000)); // Log requests slower than 2 seconds

    app.use(express.json({ limit: '10mb' }));
    app.use(express.urlencoded({ extended: true, limit: '10mb' }));

    // Health check endpoint (before rate limiting)
    app.get('/health', healthCheck);
    
    // Swagger UI
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));

    // API v1 routes
    app.use("/api/v1/users", userRouter);
    app.use("/api/v1/instructors", instructorRouter);
    app.use("/api/v1/permissions", permissionsRouter);
    app.use("/api/v1/cars", improvedCarRoutes);
    app.use("/api/v1/auth", authRouter);
    app.use("/api/v1/classes", drivingClassRouter);
    app.use("/api/v1/payments", functionalPaymentRoutes);
    app.use("/api/v1/payments", webhookRouter);
    app.use("/api/v1/payments", commissionRoutes);
    app.use("/api/v1/schedule", scheduleRouter);
    app.use("/api/v1/notifications", notificationRouter);
    app.use("/api/v1/messages", messageRoutes);
    app.use("/api/v1/admin", adminRoutes);
    
    // Iniciar tareas programadas
    SchedulerService.start();

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
        '/notifications',
        '/messages'
      ]
    });

    return app;
}


