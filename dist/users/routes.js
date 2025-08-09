"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const GenericRouter_1 = __importDefault(require("../shared/utils/classes/GenericRouter"));
class UserRouter extends GenericRouter_1.default {
    userController;
    constructor(userController) {
        super();
        this.userController = userController;
        const router = this.init();
        router.get("/allUsers", this.userController.getAll);
        router.post("/register", this.userController.register);
        router.get("/login", this.userController.login);
    }
}
exports.default = UserRouter;
