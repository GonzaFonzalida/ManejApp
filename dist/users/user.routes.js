"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const GenericRouter_1 = __importDefault(require("../shared/classes/GenericRouter"));
const user_schema_1 = require("./user.schema");
const user_middleware_1 = require("./user.middleware");
class UserRouter extends GenericRouter_1.default {
    userController;
    constructor(userController) {
        super();
        this.userController = userController;
        const router = this.init();
        router.get("/allUsers", this.userController.getAll);
        router.post("/register", (0, user_middleware_1.validate)(user_schema_1.registerSchema), this.userController.register);
        router.post("/login", (0, user_middleware_1.validate)(user_schema_1.loginSchema), this.userController.login);
    }
}
exports.default = UserRouter;
