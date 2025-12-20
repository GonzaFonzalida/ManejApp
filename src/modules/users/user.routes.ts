import UserController from "./user.controller";
import GenericRouter from "@shared/classes/GenericRouter";
import {registerSchema, loginSchema, getUserByRoleSchema} from "./user.schema" ;
import { validate } from "./user.middleware";
import { validateParams } from "@shared/middlewares/zod/validateParams";

export default class UserRouter extends GenericRouter {
    constructor(private readonly userController: UserController) {

        super();
        const router = this.init();

        router.get("/", this.userController.getAll);
        router.get("/:value", this.userController.gerUserById)
        router.get("/role/:role", validateParams(getUserByRoleSchema), this.userController.getByRol)

        router.post("/register", validate(registerSchema), this.userController.register);
        router.post("/login", validate(loginSchema), this.userController.login);
        router.post("/verify-email", this.userController.verifyEmail);
        router.get("/verify-email/:token", this.userController.verifyEmailGet);
        router.post("/resend-verification", this.userController.resendVerification);

        // Notification preferences (require authentication)
        router.get("/notification-preferences", this.userController.getNotificationPreferences);
        router.put("/notification-preferences", this.userController.updateNotificationPreferences);
    }
}