import UserService from "../users/user.services";
import DiContainer from "./DiContainer";
import UserPrismaRepository from "../users/repository/prismaUserRepository"
import userMemoryRepository from "src/users/repository/memoryUserRepository";

const diContainer = new DiContainer();

diContainer.register("UserRepository", UserPrismaRepository)
diContainer.register("userService", UserService, ["UserRepository"]);

export default diContainer;