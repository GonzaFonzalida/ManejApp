import UserService from "./services";
import { UserWithOutPassword, User, UserWithOutId } from "./types";
import { ExpressFunction } from "../shared/types/ExpressFunction"


export default class UserController {
    constructor(private userService: UserService) { }

    public register: ExpressFunction = async (req, res, next) => {
        try {
            const user: UserWithOutId = req.body;
            if (!user) return res.status(400).json({ message: "error, ingrese todos los campos" });
            await this.userService.register(user);
            res.status(201).json(user);
        } catch (error) {
            res.status(500).json({ message: "error del servidor" });
        }
    };

    public getAll: ExpressFunction = async (req, res, next) => {
        try {
            const users = await this.userService.getAllUsers();
            console.log(users)
            return res.json(users);
        } catch (error: any) {
            res.status(400).json({ message: "error interno del servidor" });
        }
    };

    public login: ExpressFunction = async (req, res, next) => {
        try {
            const userData: UserWithOutId = req.body;
            const user = await this.userService.login(userData);

            if (!user) return res.json({ message: "usuario inexistente" });

            return res.json(user);
        } catch (error: any) {
            res.status(400).json({ message: "error, ingrese el id" });
        }
    };
}
