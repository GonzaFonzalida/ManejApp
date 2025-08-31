"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const DiContainer_1 = __importDefault(require("./DiContainer"));
const prismaUserRepository_1 = __importDefault(require("../users/repositories/prismaUserRepository"));
const user_services_1 = __importDefault(require("../users/user.services"));
const user_controller_1 = __importDefault(require("src/users/user.controller"));
const PrismaInstructorRepository_1 = __importDefault(require("../instructors/repositories/PrismaInstructorRepository"));
const instructor_services_1 = __importDefault(require("src/instructors/instructor.services"));
const instructor_controller_1 = __importDefault(require("src/instructors/instructor.controller"));
const PrismaSessionRepository_1 = __importDefault(require("../auth/repositories/PrismaSessionRepository"));
const auth_services_1 = __importDefault(require("../auth/auth.services"));
const auth_controller_1 = __importDefault(require("../auth/auth.controller"));
const PrismaPermissionsRepository_1 = require("src/permissions/repositories/PrismaPermissionsRepository");
const PrismaDrivingClassRepository_1 = require("src/drivingClass/repositories/PrismaDrivingClassRepository");
const services_1 = require("src/drivingClass/services");
const controller_1 = require("src/drivingClass/controller");
const PrismaPaymentRepository_1 = __importDefault(require("../payments/repositories/PrismaPaymentRepository"));
const payment_services_1 = __importDefault(require("../payments/payment.services"));
const payment_controller_1 = __importDefault(require("../payments/payment.controller"));
const mercadopago_service_1 = __importDefault(require("../payments/mercadopago.service"));
const diContainer = new DiContainer_1.default();
//Users Instnces
diContainer.register("UserRepository", prismaUserRepository_1.default);
diContainer.register("userService", user_services_1.default, ["UserRepository"]);
diContainer.register("userController", user_controller_1.default, ["userService"]);
//Instructor Instances
diContainer.register("PrismaPermissionRepository", PrismaPermissionsRepository_1.PrismaPermissionRepository);
diContainer.register("PrismaInstructorRepository", PrismaInstructorRepository_1.default);
diContainer.register("instructorService", instructor_services_1.default, [
    "PrismaInstructorRepository",
    "UserRepository",
    "PrismaPermissionRepository"
]);
diContainer.register("instructorController", instructor_controller_1.default, ["instructorService"]);
//auth instances 
diContainer.register("PrismaSessionRepository", PrismaSessionRepository_1.default);
diContainer.register("authService", auth_services_1.default, ["PrismaSessionRepository", "UserRepository"]);
diContainer.register("authController", auth_controller_1.default, ["authService"]);
//drivingClass intances
diContainer.register("DrivingClassRepo", PrismaDrivingClassRepository_1.PrismaDrivingClassRepository);
diContainer.register("DrivingClassService", services_1.DrivingClassService, [
    "UserRepository",
    "PrismaInstructorRepository",
    "DrivingClassRepo"
]);
diContainer.register("DrivingClassController", controller_1.DrivingClassController, ["DrivingClassService"]);
//payment instances
diContainer.register("PrismaPaymentRepository", PrismaPaymentRepository_1.default);
diContainer.register("MercadoPagoService", mercadopago_service_1.default);
diContainer.register("paymentService", payment_services_1.default, ["PrismaPaymentRepository", "MercadoPagoService"]);
diContainer.register("paymentController", payment_controller_1.default, ["paymentService"]);
exports.default = diContainer;
