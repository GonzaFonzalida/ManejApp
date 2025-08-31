"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const JWT_SECRET = process.env.JWT_SECRET || "sdfsdfsdfsfd";
class UserService {
    userAuth;
    constructor(userAuth) {
        this.userAuth = userAuth;
    }
    async register(user) {
        try {
            const salt = await bcryptjs_1.default.genSalt(10);
            const hashedPassword = await bcryptjs_1.default.hash(user.password, salt);
            const result = await this.userAuth.register({
                ...user,
                password: hashedPassword,
            });
            if (result instanceof Error) {
                return result;
            }
            return result;
        }
        catch (error) {
            return error;
        }
    }
    async getUserById(value) {
        return await this.userAuth.findUser(value);
    }
    async findByRole(role) {
        return await this.userAuth.findByRole(role);
    }
    async getAllUsers() {
        return await this.userAuth.getAllUsers();
    }
    async login(user) {
        const foundUser = await this.userAuth.findByEmail(user.email);
        if (!foundUser) {
            return new Error("Usuario no encontrado");
        }
        const isPasswordValid = await bcryptjs_1.default.compare(user.password, foundUser.password);
        if (!isPasswordValid) {
            return new Error("Contraseña incorrecta");
        }
        const token = jsonwebtoken_1.default.sign({ id: foundUser.id, role: foundUser.role }, JWT_SECRET, { expiresIn: "1h" });
        return { token };
    }
}
exports.default = UserService;
