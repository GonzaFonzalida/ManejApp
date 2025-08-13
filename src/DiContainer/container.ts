import UserService from "../users/user.services";
import DiContainer from "./DiContainer";
import UserPrismaRepository from "../users/repositories/prismaUserRepository"
import userMemoryRepository from "src/users/repositories/memoryUserRepository";

const diContainer = new DiContainer();

diContainer.register("UserRepository", UserPrismaRepository)
diContainer.register("userService", UserService, ["UserRepository"]);

export default diContainer;