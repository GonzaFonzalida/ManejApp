import express from "express";
import errorHandler from "./shared/middlewares/errorMiddleware";
import notFoundHandler from "./shared/middlewares/notFoundMiddleware";
import UserRouter from "./users/routes";
import UserService from "./users/services";
import UserController from "./users/controller";
import diContainer from "./DiContainer/container"

export const buildApp = () => {
    const userService = diContainer.resolve<UserService>("userService");
    const controller = new UserController(userService);
    const routerUser = new UserRouter(controller).init();

    const app = express();
    app.use(express.json());
    app.use("/users", routerUser);

   // app.use(notFoundHandler);
    app.use(errorHandler);

    return app;
}


