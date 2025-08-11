"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildApp = void 0;
const express_1 = __importDefault(require("express"));
const errorMiddleware_1 = __importDefault(require("./shared/middlewares/errorMiddleware"));
const notFoundMiddleware_1 = __importDefault(require("./shared/middlewares/notFoundMiddleware"));
const user_routes_1 = __importDefault(require("./users/user.routes"));
const user_controller_1 = __importDefault(require("./users/user.controller"));
const container_1 = __importDefault(require("./DiContainer/container"));
const buildApp = () => {
    const userService = container_1.default.resolve("userService");
    const controller = new user_controller_1.default(userService);
    const routerUser = new user_routes_1.default(controller).init();
    const app = (0, express_1.default)();
    app.use(express_1.default.json());
    app.use("/users", routerUser);
    app.use(notFoundMiddleware_1.default);
    app.use(errorMiddleware_1.default);
    return app;
};
exports.buildApp = buildApp;
