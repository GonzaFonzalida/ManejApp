import UserController from "./controller";
import { User, UserWithOutId } from "./repository/userRepository";
import GenericRouter from "../shared/utils/classes/GenericRouter";

export default class UserRouter extends GenericRouter {
    constructor(private readonly userController: UserController) {

        super();
        const router = this.init();
        router.get("/allUsers", this.userController.getAll);

        router.post("/register", this.userController.register);

        router.get("/login", this.userController.login);
    }
}