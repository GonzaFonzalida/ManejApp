"use strict";
// C:\Users\thiag\Desktop\Back\ManejApp\src\users\user.controller.ts
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const CustomizedError_1 = __importDefault(require("../shared/classes/CustomizedError"));
class UserController {
    userService;
    constructor(userService) {
        this.userService = userService;
    }
    register = async (req, res, next) => {
        const user = req.body;
        const newUser = await this.userService.register(user);
        // Si el registro es exitoso, devolvemos el token
        if (newUser.name == "PrismaClientKnownRequestError") {
            return next(new CustomizedError_1.default("El usuario que intenta registrar ya existe", 409));
        }
        res.status(201).json({
            token: newUser,
        });
    };
    getAll = async (req, res, next) => {
        try {
            const users = await this.userService.getAllUsers();
            return res.json(users);
        }
        catch (e) {
            // Pasamos cualquier error al siguiente middleware de error
            next(e);
        }
    };
    getByRol = async (req, res, next) => {
        try {
            const role = req.params.role;
            const users = await this.userService.findByRole(role.toUpperCase());
            return res.json(users);
        }
        catch (e) {
            next(e);
        }
    };
    gerUserById = async (req, res, next) => {
        try {
            const value = req.params.value;
            const user = await this.userService.getUserById(value);
            if (!user) {
                next(new CustomizedError_1.default("Usuario No Encontrado", 404));
            }
            return res.json(user);
        }
        catch (error) {
            next(error);
        }
    };
    login = async (req, res, next) => {
        try {
            const userData = req.body;
            const user = await this.userService.login(userData);
            if (!user) {
                // Si el usuario no existe, devolvemos un status 401 (Unauthorized)
                return next(new CustomizedError_1.default("Credenciales inválidas", 401));
            }
            return res.json(user);
        }
        catch (error) {
            // Pasamos cualquier error al siguiente middleware de error
            next(error);
        }
    };
}
exports.default = UserController;
