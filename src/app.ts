import express from "express";
import diContainer from "./DiContainer/container"
import errorHandler from "./shared/middlewares/errorMiddleware";
import notFoundHandler from "./shared/middlewares/notFoundMiddleware";

import UserRouter from "./users/user.routes";
import UserController from "./users/user.controller";

import InstructorController from "./instructors/instructor.controller";
import InstructorRouter from "./instructors/instructor.routes";

import AuthController from "@auth/auth.controller";
import buildAuthRouter from "@auth/auth.routes";
import permissionsRouter from "./permissions/permissions.routes";
import carRouters from "./cars/cars.routes";

export const buildApp = () => {

    const userController = diContainer.resolve<UserController>("userController");
    const userRouter = new UserRouter(userController).init();

    const instructorController = diContainer.resolve<InstructorController>("instructorController");
    const instructorRouter = new InstructorRouter(instructorController).init();

    const authController = diContainer.resolve<AuthController>("authController");
    const authRouter = buildAuthRouter(authController);
    const app = express();

    app.use(express.json());

    app.use("/users", userRouter);
    app.use("/instructors", instructorRouter);
    app.use("/permissions", permissionsRouter)
    app.use("/cars", carRouters)
    app.use("/auth", authRouter);
    //modulos
    // app.use("/permissons");
    // app.use("/admin");
    // app.use("/cars")

    app.use(notFoundHandler);
    app.use(errorHandler);

    return app;
}


