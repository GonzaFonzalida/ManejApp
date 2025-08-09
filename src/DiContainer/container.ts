import UserService from "../users/services";
import DiContainer from "./DiContainer";
import UserPrismaRepository from "../users/repository/prismaUserRepository"
const diContainer = new DiContainer();

diContainer.register("UserRepository", UserPrismaRepository)
diContainer.register("userService", UserService, ["UserRepository"]);

export default diContainer;