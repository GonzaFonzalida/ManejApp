"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.buildApp = void 0;
const express_1 = __importDefault(require("express"));
const routes_1 = __importDefault(require("./users/routes"));
const controller_1 = __importDefault(require("./users/controller"));
const container_1 = __importDefault(require("./DiContainer/container"));
const buildApp = () => {
    const userService = container_1.default.resolve("userService");
    const controller = new controller_1.default(userService);
    const routerUser = new routes_1.default(controller).init();
    const app = (0, express_1.default)();
    app.use(express_1.default.json());
    app.use("/users", routerUser);
    // app.use(notFoundHandler);
    // app.use(errorHandler);
    return app;
};
exports.buildApp = buildApp;
