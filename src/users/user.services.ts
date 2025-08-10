import { User, UserWithOutPassword, UserWithOutId, UserWithDates } from "./user.types";
import { UserRepository } from "./repository/userRepository";

export default class UserService {
    constructor(private userAuth: UserRepository) { }
    async register(user: UserWithDates): Promise<UserWithOutPassword | Error> {

        return await this.userAuth.register(user);
    }
    async getAllUsers(): Promise<UserWithOutPassword[]> {

        return await this.userAuth.getAllUsers();
    }

    async login(user: UserWithOutId): Promise<UserWithOutPassword | undefined> {

        return await this.userAuth.login(user);
    }
}


