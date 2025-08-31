import DiContainer from "./DiContainer";

import UserPrismaRepository from "../users/repositories/prismaUserRepository"
import UserService from "../users/user.services";
import UserController from "src/users/user.controller";

import PrismaInstructorRepository from "../instructors/repositories/PrismaInstructorRepository"
import InstructorService from "src/instructors/instructor.services";
import InstructorController from "src/instructors/instructor.controller";

import PrismaSessionRepository from "@auth/repositories/PrismaSessionRepository";
import AuthService from "@auth/auth.services";
import AuthController from "@auth/auth.controller";
import { PrismaPermissionRepository } from "src/permissions/repositories/PrismaPermissionsRepository";

import { PrismaDrivingClassRepository } from "src/drivingClass/repositories/PrismaDrivingClassRepository";
import { DrivingClassService } from "src/drivingClass/services";
import { DrivingClassController } from "src/drivingClass/controller";

import PrismaPaymentRepository from "../payments/repositories/PrismaPaymentRepository";
import PaymentService from "../payments/payment.services";
import PaymentController from "../payments/payment.controller";
import MercadoPagoService from "../payments/mercadopago.service";

const diContainer = new DiContainer();
//Users Instnces
diContainer.register("UserRepository", UserPrismaRepository);
diContainer.register("userService", UserService, ["UserRepository"]);
diContainer.register("userController", UserController, ["userService"]);

//Instructor Instances
diContainer.register("PrismaPermissionRepository", PrismaPermissionRepository)
diContainer.register("PrismaInstructorRepository", PrismaInstructorRepository);
diContainer.register("instructorService", InstructorService,[
    "PrismaInstructorRepository",
    "UserRepository",
    "PrismaPermissionRepository"
]);
diContainer.register("instructorController", InstructorController, ["instructorService"]);

//auth instances 
diContainer.register("PrismaSessionRepository", PrismaSessionRepository);
diContainer.register("authService", AuthService, ["PrismaSessionRepository","UserRepository"]);
diContainer.register("authController", AuthController, ["authService"]);

//drivingClass intances
diContainer.register("DrivingClassRepo", PrismaDrivingClassRepository);
diContainer.register("DrivingClassService", DrivingClassService, [
    "UserRepository",
    "PrismaInstructorRepository",
    "DrivingClassRepo"
]);
diContainer.register("DrivingClassController", DrivingClassController, ["DrivingClassService"]);

//payment instances
diContainer.register("PrismaPaymentRepository", PrismaPaymentRepository);
diContainer.register("MercadoPagoService", MercadoPagoService);
diContainer.register("paymentService", PaymentService, ["PrismaPaymentRepository", "MercadoPagoService"]);
diContainer.register("paymentController", PaymentController, ["paymentService"]);

export default diContainer;