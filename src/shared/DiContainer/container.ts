import DiContainer from "./DiContainer";

import UserPrismaRepository from "../../users/repositories/prismaUserRepository";
import UserService from "../../users/user.services";
import UserController from "../../users/user.controller";

import PrismaInstructorRepository from "../../modules/instructors/repositories/PrismaInstructorRepository";
import InstructorService from "../../modules/instructors/instructor.services";
import InstructorController from "../../modules/instructors/instructor.controller";

import PrismaSessionRepository from "src/modules/auth/repositories/PrismaSessionRepository";
import AuthService from "src/modules/auth/auth.services";
import AuthController from "src/modules/auth/auth.controller";
import { PrismaPermissionRepository } from "../../modules/permissions/repositories/PrismaPermissionsRepository";

import { PrismaDrivingClassRepository } from "../../modules/drivingClass/repositories/PrismaDrivingClassRepository";
import { DrivingClassService } from "../../modules/drivingClass/services";
import { DrivingClassController } from "../../modules/drivingClass/controller";

import PrismaPaymentRepository from "../../modules/payments/repositories/PrismaPaymentRepository";
import PaymentService from "../../modules/payments/payment.services";
import PaymentController from "../../modules/payments/payment.controller";
import MercadoPagoService from "../../modules/payments/mercadopago.service";

import { PrismaScheduleSlotRepository } from "../../modules/schedule/repositories/PrismaScheduleSlotRepository";
import { ScheduleService } from "../../modules/schedule/schedule.service";
import { ScheduleController } from "../../modules/schedule/schedule.controller";

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

//schedule instances
diContainer.register("PrismaScheduleSlotRepository", PrismaScheduleSlotRepository);
diContainer.register("scheduleService", ScheduleService, [
  "PrismaScheduleSlotRepository",
  "instructorService",
  "DrivingClassService",
  "paymentService"
]);
diContainer.register("scheduleController", ScheduleController, ["scheduleService"]);

export default diContainer;