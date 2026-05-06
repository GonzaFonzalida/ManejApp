"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildApp = void 0;
const express_1 = __importDefault(require("express"));
const cookie_parser_1 = __importDefault(require("cookie-parser"));
const swaggerJSDoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const cors_1 = __importDefault(require("cors"));
const container_1 = __importDefault(require("./shared/DiContainer/container"));
const errorMiddleware_1 = __importDefault(require("./shared/middlewares/errorMiddleware"));
const notFoundMiddleware_1 = __importDefault(require("./shared/middlewares/notFoundMiddleware"));
const requestLogger_1 = require("./shared/logging/middleware/requestLogger");
const LoggerConfig_1 = require("./shared/logging/LoggerConfig");
const security_1 = require("./shared/middlewares/security");
const config_1 = require("./config/config");
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
    /** Respuesta JSON pública para Flutter / clientes (GET /api/v1/config). */
    const sendPublicConfig = (_req, res) => {
        res.json({
            baseUrl: config_1.APP_URL.replace(/\/$/, ''),
            googleClientId: config_1.GOOGLE_CLIENT_ID || undefined,
        });
    };
    /** Todas las rutas versionadas bajo un solo prefijo (fuente de verdad: /api/v1/*). */
    const apiV1 = express_1.default.Router();
    apiV1.get('/config', sendPublicConfig);
    apiV1.use('/users', userRouter);
    apiV1.use('/instructors', instructorRouter);
    apiV1.use('/permissions', permissions_routes_1.default);
    apiV1.use('/cars', improved_cars_routes_1.default);
    apiV1.use('/auth', authRouter);
    apiV1.use('/classes', drivingClassRouter);
    // Webhook primero; commission antes que functional para que /commission-report no caiga en GET /:id
    apiV1.use('/payments', functional_payment_routes_1.webhookRouter);
    apiV1.use('/payments', commission_routes_1.default);
    apiV1.use('/payments', functional_payment_routes_1.functionalPaymentRoutes);
    apiV1.use('/schedule', scheduleRouter);
    apiV1.use('/notifications', notificationRouter);
    apiV1.use('/messages', messages_routes_1.default);
    apiV1.use('/admin', admin_routes_1.default);
    // Trust proxy for production (behind reverse proxy/load balancer)
    // Set to 1 to trust the first proxy (common for single proxy setups)
    app.set('trust proxy', 1);
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
                    url: `${config_1.APP_URL.replace(/\/$/, '')}/api/v1`,
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
    app.use((0, cookie_parser_1.default)());
    app.use(express_1.default.json({ limit: '10mb' }));
    app.use(express_1.default.urlencoded({ extended: true, limit: '10mb' }));
    // Health check endpoint (before rate limiting)
    app.get('/health', healthCheck_1.healthCheck);
    // Swagger UI
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs));
    // API v1 — prefijo único
    app.use('/api/v1', apiV1);
    /**
     * Compatibilidad legacy (deprecated): mismos routers montados sin /api/v1.
     * Preferir siempre /api/v1/*. Mantener solo mientras existan clientes antiguos.
     */
    app.use('/users', userRouter);
    app.use('/instructors', instructorRouter);
    app.use('/permissions', permissions_routes_1.default);
    app.use('/cars', improved_cars_routes_1.default);
    app.use('/auth', authRouter);
    app.use('/classes', drivingClassRouter);
    app.use('/payments', functional_payment_routes_1.webhookRouter);
    app.use('/payments', commission_routes_1.default);
    app.use('/payments', functional_payment_routes_1.functionalPaymentRoutes);
    app.use('/schedule', scheduleRouter);
    app.use('/notifications', notificationRouter);
    app.use('/messages', messages_routes_1.default);
    app.use('/admin', admin_routes_1.default);
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
        apiV1Base: '/api/v1',
        routes: [
            '/api/v1/config',
            '/api/v1/users',
            '/api/v1/instructors',
            '/api/v1/permissions',
            '/api/v1/cars',
            '/api/v1/auth',
            '/api/v1/classes',
            '/api/v1/payments',
            '/api/v1/schedule',
            '/api/v1/notifications',
            '/api/v1/messages',
            '/api/v1/admin',
            '/health',
            '/api-docs',
        ],
        legacyRoutesDeprecated: [
            '/users',
            '/instructors',
            '/permissions',
            '/cars',
            '/auth',
            '/classes',
            '/payments',
            '/schedule',
            '/notifications',
            '/messages',
            '/admin',
        ],
    });
    return app;
};
exports.buildApp = buildApp;
