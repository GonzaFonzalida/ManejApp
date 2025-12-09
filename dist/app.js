"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildApp = void 0;
const express_1 = __importDefault(require("express"));
const swaggerJSDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const cors_1 = __importDefault(require("cors"));
const container_1 = __importDefault(require("./shared/DiContainer/container"));
const errorMiddleware_1 = __importDefault(require("./shared/middlewares/errorMiddleware"));
const notFoundMiddleware_1 = __importDefault(require("./shared/middlewares/notFoundMiddleware"));
const requestLogger_1 = require("./shared/logging/middleware/requestLogger");
const LoggerConfig_1 = require("./shared/logging/LoggerConfig");
const security_1 = require("./shared/middlewares/security");
const validation_1 = require("./shared/middlewares/validation");
const healthCheck_1 = require("./shared/middlewares/healthCheck");
const advancedValidation_1 = require("./shared/middlewares/advancedValidation");
const user_routes_1 = __importDefault(require("./modules/users/user.routes"));
const instructor_routes_1 = __importDefault(require("./modules/instructors/instructor.routes"));
const auth_routes_1 = __importDefault(require("./modules/auth/auth.routes"));
const permissions_routes_1 = __importDefault(require("./modules/permissions/permissions.routes"));
const improved_cars_routes_1 = __importDefault(require("./modules/cars/improved-cars.routes"));
const routes_1 = __importDefault(require("./modules/drivingClass/routes"));
const functional_payment_routes_1 = require("./modules/payments/functional-payment.routes");
const commission_routes_1 = __importDefault(require("./modules/payments/commission.routes"));
const schedule_routes_1 = require("./modules/schedule/schedule.routes");
const routes_2 = require("./modules/notifications/routes");
const messages_routes_1 = __importDefault(require("./modules/messages/messages.routes"));
const admin_routes_1 = __importDefault(require("./modules/admin/admin.routes"));
const SchedulerService_1 = __importDefault(require("./shared/services/SchedulerService"));
const buildApp = () => {
    const userController = container_1.default.resolve("userController");
    const userRouter = new user_routes_1.default(userController).init();
    const instructorController = container_1.default.resolve("instructorController");
    const instructorRouter = new instructor_routes_1.default(instructorController).init();
    const authController = container_1.default.resolve("authController");
    const authRouter = (0, auth_routes_1.default)(authController);
    const drivingClassController = container_1.default.resolve("DrivingClassController");
    const drivingClassRouter = new routes_1.default(drivingClassController).init();
    // Payment routes are now self-contained
    const scheduleController = container_1.default.resolve("scheduleController");
    const scheduleRouter = new schedule_routes_1.ScheduleRouter(scheduleController).init();
    const notificationController = container_1.default.resolve("notificationController");
    const notificationRouter = new routes_2.NotificationRoutes(notificationController).getRouter();
    const messageController = container_1.default.resolve("messageController");
    const app = (0, express_1.default)();
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
    app.use(security_1.helmetConfig);
    app.use((0, cors_1.default)(security_1.corsOptions));
    app.use(security_1.generalRateLimit);
    app.use(advancedValidation_1.preventSQLInjection);
    app.use(advancedValidation_1.preventXSS);
    app.use(validation_1.sanitizeInput);
    // Logging middlewares
    app.use(requestLogger_1.requestLoggerMiddleware);
    app.use((0, requestLogger_1.performanceLoggerMiddleware)(2000)); // Log requests slower than 2 seconds
    app.use(express_1.default.json({ limit: '10mb' }));
    app.use(express_1.default.urlencoded({ extended: true, limit: '10mb' }));
    // Health check endpoint (before rate limiting)
    app.get('/health', healthCheck_1.healthCheck);
    // Swagger UI
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
    // API v1 routes
    app.use("/api/v1/users", userRouter);
    app.use("/api/v1/instructors", instructorRouter);
    app.use("/api/v1/permissions", permissions_routes_1.default);
    app.use("/api/v1/cars", improved_cars_routes_1.default);
    app.use("/api/v1/auth", authRouter);
    app.use("/api/v1/classes", drivingClassRouter);
    app.use("/api/v1/payments", functional_payment_routes_1.functionalPaymentRoutes);
    app.use("/api/v1/payments", functional_payment_routes_1.webhookRouter);
    app.use("/api/v1/payments", commission_routes_1.default);
    app.use("/api/v1/schedule", scheduleRouter);
    app.use("/api/v1/notifications", notificationRouter);
    app.use("/api/v1/messages", messages_routes_1.default);
    app.use("/api/v1/admin", admin_routes_1.default);
    // Iniciar tareas programadas
    SchedulerService_1.default.start();
    app.use(notFoundMiddleware_1.default);
    app.use(requestLogger_1.errorLoggerMiddleware); // Log errors before handling them
    app.use(errorMiddleware_1.default);
    // Log application startup
    LoggerConfig_1.logger.info('ManejApp initialized successfully', {
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
};
exports.buildApp = buildApp;
