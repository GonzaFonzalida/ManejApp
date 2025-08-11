"use strict";
// C:\Users\thiag\Desktop\Back\ManejApp\src\users\user.controller.ts
Object.defineProperty(exports, "__esModule", { value: true });
class UserController {
    userService;
    constructor(userService) {
        this.userService = userService;
    }
    register = async (req, res, next) => {
        try {
            const user = req.body;
            const newUser = await this.userService.register(user);
            // Si el registro es exitoso, devolvemos el token
            res.status(201).json({
                token: newUser,
            });
        }
        catch (error) {
            // Manejamos el error específico del repositorio
            if (error.message.includes('El campo') && error.message.includes('ya está en uso.')) {
                // Devolvemos un status 409 (Conflict) con el mensaje claro.
                return res.status(409).json({ message: error.message });
            }
            // Si es otro tipo de error, lo pasamos al siguiente middleware de error
            next(error);
        }
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
    login = async (req, res, next) => {
        try {
            const userData = req.body;
            const user = await this.userService.login(userData);
            if (!user) {
                // Si el usuario no existe, devolvemos un status 401 (Unauthorized)
                return res.status(401).json({ message: "Credenciales inválidas" });
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
