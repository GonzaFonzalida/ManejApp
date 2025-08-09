"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class UserController {
    userService;
    constructor(userService) {
        this.userService = userService;
    }
    register = async (req, res, next) => {
        try {
            const user = req.body;
            if (!user)
                return res.status(400).json({ message: "error, ingrese todos los campos" });
            await this.userService.register(user);
            res.status(201).json(user);
        }
        catch (error) {
            res.status(500).json({ message: "error del servidor" });
        }
    };
    getAll = async (req, res, next) => {
        try {
            const users = await this.userService.getAllUsers();
            console.log(users);
            return res.json(users);
        }
        catch (error) {
            res.status(400).json({ message: "error interno del servidor" });
        }
    };
    login = async (req, res, next) => {
        try {
            const userData = req.body;
            const user = await this.userService.login(userData);
            if (!user)
                return res.json({ message: "usuario inexistente" });
            return res.json(user);
        }
        catch (error) {
            res.status(400).json({ message: "error, ingrese el id" });
        }
    };
}
exports.default = UserController;
