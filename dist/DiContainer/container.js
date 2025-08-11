"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const user_services_1 = __importDefault(require("../users/user.services"));
const DiContainer_1 = __importDefault(require("./DiContainer"));
const prismaUserRepository_1 = __importDefault(require("../users/repository/prismaUserRepository"));
const diContainer = new DiContainer_1.default();
diContainer.register("UserRepository", prismaUserRepository_1.default);
diContainer.register("userService", user_services_1.default, ["UserRepository"]);
exports.default = diContainer;
