import DiContainer from "./DiContainer";

import UserPrismaRepository from "@users/repositories/prismaUserRepository";
import UserService from "@users/user.services";
import UserController from "@users/user.controller";

import PrismaInstructorRepository from "@instructors/repositories/PrismaInstructorRepository";
import InstructorService from "@instructors/instructor.services";
import InstructorController from "@instructors/instructor.controller";

import PrismaSessionRepository from "@auth/repositories/PrismaSessionRepository";
import AuthService from "@auth/auth.services";
import AuthController from "@auth/auth.controller";
import { PrismaPermissionRepository } from "@permissions/repositories/PrismaPermissionsRepository";

import { PrismaDrivingClassRepository } from "@drivingClass/repositories/PrismaDrivingClassRepository";
import { DrivingClassService } from "@drivingClass/services";
import { DrivingClassController } from "@drivingClass/controller";

import PrismaPaymentRepository from "@payments/repositories/PrismaPaymentRepository";
import PaymentService from "@payments/payment.services";
import PaymentController from "@payments/payment.controller";
import MercadoPagoService from "@payments/mercadopago.service";
import CommissionPaymentService from "@payments/commission-payment.service";
import CommissionEnhancedService from "@payments/commission-enhanced.service";

import { PrismaScheduleSlotRepository } from "@schedule/repositories/PrismaScheduleSlotRepository";
import { ScheduleService } from "@schedule/schedule.service";
import { ScheduleController } from "@schedule/schedule.controller";

import { PrismaNotificationTokenRepository } from "@notifications/repositories/PrismaNotificationTokenRepository";
import { NotificationService } from "@notifications/service";
import { NotificationController } from "@notifications/controller";
import { logger } from "@logging/LoggerConfig";

import PrismaMessageRepository from "../../modules/messages/repositories/PrismaMessageRepository";
import MessageService from "../../modules/messages/messages.services";
import MessageController from "../../modules/messages/messages.controller";

import EmailService from "@shared/services/EmailService";

const diContainer = new DiContainer();
//Users Instnces
diContainer.register("UserRepository", UserPrismaRepository);
diContainer.register("userService", UserService, ["UserRepository", "emailService"]);
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
diContainer.register("CommissionPaymentService", CommissionPaymentService);
diContainer.register("CommissionEnhancedService", CommissionEnhancedService, ["PrismaPaymentRepository", "CommissionPaymentService"]);
diContainer.register("paymentService", PaymentService, ["PrismaPaymentRepository", "MercadoPagoService"]);
diContainer.register("paymentController", PaymentController, ["paymentService", "CommissionEnhancedService"]);

//schedule instances
diContainer.register("PrismaScheduleSlotRepository", PrismaScheduleSlotRepository);
diContainer.register("scheduleService", ScheduleService, [
  "PrismaScheduleSlotRepository",
  "instructorService",
  "DrivingClassService",
  "paymentService"
]);
diContainer.register("scheduleController", ScheduleController, ["scheduleService"]);

//notification instances
diContainer.register("PrismaNotificationTokenRepository", PrismaNotificationTokenRepository);
diContainer.registerInstance("logger", logger);
diContainer.register("notificationService", NotificationService, [
  "logger",
  "PrismaNotificationTokenRepository",
  "UserRepository"
]);
diContainer.register("notificationController", NotificationController, [
  "notificationService",
  "logger"
]);

//messages instances
diContainer.register("PrismaMessageRepository", PrismaMessageRepository);
diContainer.register("messageService", MessageService, ["PrismaMessageRepository"]);
diContainer.register("messageController", MessageController, ["messageService"]);

//email service
diContainer.register("emailService", EmailService);

export default diContainer;