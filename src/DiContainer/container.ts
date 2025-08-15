import DiContainer from "./DiContainer";
import UserPrismaRepository from "../users/repositories/prismaUserRepository"
import UserService from "../users/user.services";
import PrismaInstructorRepository from "../instructors/repositories/PrismaInstructorRepository"
import InstructorService from "src/instructors/instructor.services";
const diContainer = new DiContainer();

diContainer.register("UserRepository", UserPrismaRepository);
diContainer.register("userService", UserService, ["UserRepository"]);

diContainer.register("PrismaInstructorRepository", PrismaInstructorRepository);
diContainer.register("instructorService", InstructorService, ["PrismaInstructorRepository"]);


export default diContainer;