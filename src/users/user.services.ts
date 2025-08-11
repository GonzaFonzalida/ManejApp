// C:\Users\thiag\Desktop\Back\ManejApp\src\users\user.services.ts

import { UserWithOutPassword, UserWithDates, UserWithOutId } from "./user.types";
import { UserRepository } from "./repository/userRepository";

export default class UserService {
    constructor(private userAuth: UserRepository) { }

    async register(user: UserWithDates): Promise<UserWithOutId | Error> {
        try {
            // El repositorio devolverá un objeto con la propiedad 'id' si el registro es exitoso.
            const result = await this.userAuth.register(user);
            if (result instanceof Error) {
                return result;
            }
            if ('password' in result) {
                return result as UserWithOutId;
            }
            return new Error("Returned user object does not have required 'password' property.");
        } catch (error: any) {
            return error as Error;
        }
    }

    async getAllUsers(): Promise<UserWithOutPassword[]> {
        return await this.userAuth.getAllUsers();
    }

    async login(user: UserWithOutId): Promise<UserWithOutPassword | undefined> {
        return await this.userAuth.login(user);
    }
}
