import UserService from "./user.services";
import { UserWithOutPassword, User, UserWithOutId, UserWithDates } from "./user.types";
import { ExpressFunction } from "../shared/types/ExpressFunction"
import CustomizedError from "../shared/classes/CustomizedError";

export default class UserController {
    constructor(private userService: UserService) { }

    public register: ExpressFunction = async (req, res, next) => {
        const user: UserWithDates = req.body;
        
        await this.userService.register(user);
        res.status(201).json(user);

    };

    public getAll: ExpressFunction = async (req, res, next) => {
        try{
            const users = await this.userService.getAllUsers();
            return res.json(users);
        } catch (e){
            next(e);
        }
    };

    public login: ExpressFunction = async (req, res, next) => {
        try {
            const userData: UserWithOutId = req.body;
            const user = await this.userService.login(userData);

            if (!user) return res.json({ message: "usuario inexistente" });

            return res.json(user);
        } catch (error) {
            res.status(400).json({ message: "error, ingrese el id" });
        }
    };
}
