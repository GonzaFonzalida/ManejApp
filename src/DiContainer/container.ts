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

const diContainer = new DiContainer();
//Users Instnces
diContainer.register("UserRepository", UserPrismaRepository);
diContainer.register("userService", UserService, ["UserRepository"]);
diContainer.register("userController", UserController, ["userService"]);

//Instructor Instances
diContainer.register("PrismaInstructorRepository", PrismaInstructorRepository);
diContainer.register("instructorService", InstructorService, ["PrismaInstructorRepository","UserRepository"]);
diContainer.register("instructorController", InstructorController, ["instructorService"]);

//auth instances 
diContainer.register("PrismaSessionRepository", PrismaSessionRepository);
diContainer.register("authService", AuthService, ["PrismaSessionRepository","UserRepository"]);
diContainer.register("authController", AuthController, ["authService"]);
export default diContainer;