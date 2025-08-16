import express from "express";
import diContainer from "./DiContainer/container"

import errorHandler from "./shared/middlewares/errorMiddleware";
import notFoundHandler from "./shared/middlewares/notFoundMiddleware";

import UserRouter from "./users/user.routes";
import UserService from "./users/user.services";
import UserController from "./users/user.controller";

import InstructorService from "./instructors/instructor.services"
import InstructorController from "./instructors/instructor.controller";
import InstructorRouter from "./instructors/instructor.routes";
export const buildApp = () => {

    const userService = diContainer.resolve<UserService>("userService");
    const userController = new UserController(userService);
    const routerUser = new UserRouter(userController).init();

    const instructorService = diContainer.resolve<InstructorService>("instructorService");
    const instructorController = new InstructorController(instructorService);
    const instructorRouter = new InstructorRouter(instructorController).init();

    const app = express();

    app.use(express.json());
    app.use("/users", routerUser);
    app.use("/instructors", instructorRouter)
    

    app.use(notFoundHandler);
    app.use(errorHandler);

    return app;
}


