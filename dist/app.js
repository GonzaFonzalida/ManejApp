"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildApp = void 0;
const express_1 = __importDefault(require("express"));
const swaggerJSDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const container_1 = __importDefault(require("./shared/DiContainer/container"));
const errorMiddleware_1 = __importDefault(require("./shared/middlewares/errorMiddleware"));
const notFoundMiddleware_1 = __importDefault(require("./shared/middlewares/notFoundMiddleware"));
const requestLogger_1 = require("./shared/logging/middleware/requestLogger");
const LoggerConfig_1 = require("./shared/logging/LoggerConfig");
const user_routes_1 = __importDefault(require("./modules/users/user.routes"));
const instructor_routes_1 = __importDefault(require("./modules/instructors/instructor.routes"));
const auth_routes_1 = __importDefault(require("./modules/auth/auth.routes"));
const permissions_routes_1 = __importDefault(require("./modules/permissions/permissions.routes"));
const cars_routes_1 = __importDefault(require("./modules/cars/cars.routes"));
const routes_1 = __importDefault(require("./modules/drivingClass/routes"));
const payment_routes_1 = __importDefault(require("./modules/payments/payment.routes"));
const schedule_routes_1 = require("./modules/schedule/schedule.routes");
const routes_2 = require("./modules/notifications/routes");
const buildApp = () => {
    const userController = container_1.default.resolve("userController");
    const userRouter = new user_routes_1.default(userController).init();
    const instructorController = container_1.default.resolve("instructorController");
    const instructorRouter = new instructor_routes_1.default(instructorController).init();
    const authController = container_1.default.resolve("authController");
    const authRouter = (0, auth_routes_1.default)(authController);
    const drivingClassController = container_1.default.resolve("DrivingClassController");
    const drivingClassRouter = new routes_1.default(drivingClassController).init();
    const paymentController = container_1.default.resolve("paymentController");
    const paymentRouter = new payment_routes_1.default(paymentController).init();
    const scheduleController = container_1.default.resolve("scheduleController");
    const scheduleRouter = new schedule_routes_1.ScheduleRouter(scheduleController).init();
    const notificationController = container_1.default.resolve("notificationController");
    const notificationRouter = new routes_2.NotificationRoutes(notificationController).getRouter();
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
    app.use(requestLogger_1.requestLoggerMiddleware);
    app.use((0, requestLogger_1.performanceLoggerMiddleware)(2000)); // Log requests slower than 2 seconds
    app.use(express_1.default.json());
    // Swagger UI
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
    app.use("/users", userRouter);
    app.use("/instructors", instructorRouter);
    app.use("/permissions", permissions_routes_1.default);
    app.use("/cars", cars_routes_1.default);
    app.use("/auth", authRouter);
    app.use("/classes", drivingClassRouter);
    app.use("/payments", paymentRouter);
    app.use("/schedule", scheduleRouter);
    app.use("/notifications", notificationRouter);
    //modulos
    // app.use("/permissions"); // ya registrado arriba
    // app.use("/admin");
    // app.use("/cars") // ya registrado arriba
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
            '/notifications'
        ]
    });
    return app;
};
exports.buildApp = buildApp;
