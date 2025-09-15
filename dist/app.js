"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildApp = void 0;
const express_1 = __importDefault(require("express"));
const container_1 = __importDefault(require("./DiContainer/container"));
const errorMiddleware_1 = __importDefault(require("./shared/middlewares/errorMiddleware"));
const notFoundMiddleware_1 = __importDefault(require("./shared/middlewares/notFoundMiddleware"));
const requestLogger_1 = require("./shared/logging/middleware/requestLogger");
const LoggerConfig_1 = require("./shared/logging/LoggerConfig");
const user_routes_1 = __importDefault(require("./users/user.routes"));
const instructor_routes_1 = __importDefault(require("./instructors/instructor.routes"));
const auth_routes_1 = __importDefault(require("./auth/auth.routes"));
const permissions_routes_1 = __importDefault(require("./permissions/permissions.routes"));
const cars_routes_1 = __importDefault(require("./cars/cars.routes"));
const routes_1 = __importDefault(require("./drivingClass/routes"));
const payment_routes_1 = __importDefault(require("./payments/payment.routes"));
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
    const app = (0, express_1.default)();
    // Logging middlewares (should be first)
    app.use(requestLogger_1.requestLoggerMiddleware);
    app.use((0, requestLogger_1.performanceLoggerMiddleware)(2000)); // Log requests slower than 2 seconds
    app.use(express_1.default.json());
    app.use("/users", userRouter);
    app.use("/instructors", instructorRouter);
    app.use("/permissions", permissions_routes_1.default);
    app.use("/cars", cars_routes_1.default);
    app.use("/auth", authRouter);
    app.use("/classes", drivingClassRouter);
    app.use("/payments", paymentRouter);
    //modulos
    // app.use("/permissons");
    // app.use("/admin");
    // app.use("/cars")
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
            '/payments'
        ]
    });
    return app;
};
exports.buildApp = buildApp;
