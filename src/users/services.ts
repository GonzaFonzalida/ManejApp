import { User, UserWithOutPassword, UserWithOutId } from "./types";
import { UserRepository } from "./repository/userRepository";

export default class UserService {
    constructor(private userAuth: UserRepository) { }
    async register(user: UserWithOutId): Promise<UserWithOutPassword | Error> {
        console.log(this.userAuth.register(user));
        return await this.userAuth.register(user);
    }
    async getAllUsers(): Promise<UserWithOutPassword[]> {
        console.log(this.userAuth.getAllUsers());
        return await this.userAuth.getAllUsers();
    }

    async login(user: UserWithOutId): Promise<UserWithOutPassword | undefined> {
        console.log(this.userAuth.login(user));
        return await this.userAuth.login(user);
    }
}


