import UserController from "./user.controller";
import GenericRouter from "../shared/classes/GenericRouter";
import {registerSchema, loginSchema} from "./user.schema" ;
import { validate } from "./user.middleware";

export default class UserRouter extends GenericRouter {
    constructor(private readonly userController: UserController) {

        super();
        const router = this.init();
        router.get("/", this.userController.getAll);

        router.get("/:value", this.userController.gerUserById)

        router.post("/register", validate(registerSchema), this.userController.register);

        router.post("/login", validate(loginSchema), this.userController.login);
    }
}