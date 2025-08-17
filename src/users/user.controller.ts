// C:\Users\thiag\Desktop\Back\ManejApp\src\users\user.controller.ts

import UserService from "./user.services";
import { UserWithOutPassword, User, UserWithOutId, UserWithDates } from "./user.types";
import { ExpressFunction } from "../shared/types/ExpressFunction"
import CustomizedError from "../shared/classes/CustomizedError";

export default class UserController {
    constructor(private userService: UserService) { }

    public register: ExpressFunction = async (req, res, next) => {
        try {
            const user: UserWithDates = req.body;
            const newUser = await this.userService.register(user);

            // Si el registro es exitoso, devolvemos el token
            res.status(201).json({
                token: newUser,
            });
        } catch (error: any) {
            // Manejamos el error específico del repositorio
            if (error.message.includes('El campo') && error.message.includes('ya está en uso.')) {
                // Devolvemos un status 409 (Conflict) con el mensaje claro.
                return res.status(409).json({ message: error.message });
            }
            // Si es otro tipo de error, lo pasamos al siguiente middleware de error
            next(error);
        }
    };

    public getAll: ExpressFunction = async (req, res, next) => {
        try{
            const users = await this.userService.getAllUsers();
            return res.json(users);
        } catch (e){
            // Pasamos cualquier error al siguiente middleware de error
            next(e);
        }
    };

    public getByRol: ExpressFunction = async (req, res, next) => {
        try{
            const role = req.params.role

            const users = await this.userService.findByRole(role.toUpperCase());
            return res.json(users);
        } catch (e){
            
            next(e);
        }
    };

    public gerUserById : ExpressFunction = async (req, res, next) =>{
         try {
            const value = req.params.value;
            const user = await this.userService.getUserById(value);

            if (!user) {
                next( new CustomizedError("Usuario No Encontrado", 404));
            }

            return res.json(user);
        } catch (error) {
            next(error);
        }
    }

    public login: ExpressFunction = async (req, res, next) => {
        try {
            const userData: UserWithOutId = req.body;
            const user = await this.userService.login(userData);

            if (!user) {
                // Si el usuario no existe, devolvemos un status 401 (Unauthorized)
                return next(new CustomizedError("Credenciales inválidas", 401));
            }

            return res.json(user);
        } catch (error) {
            // Pasamos cualquier error al siguiente middleware de error
            next(error);
        }
    };
}
