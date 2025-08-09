import { User, UserWithOutPassword, UserWithOutId } from "./types";
import { UserRepository } from "./repository/userRepository";

export default class UserService {
    constructor(private userAuth: UserRepository) { }

    async register(user: UserWithOutId): Promise<UserWithOutPassword | Error> {
        // Usa una sola llamada con 'await' y 'console.log' para un mejor manejo
        try {
            const newUser = await this.userAuth.register(user);
            console.log('Usuario registrado:', newUser);
            return newUser;
        } catch (error) {
            console.error('Error en el servicio de registro:', error);
            return new Error('Error al registrar el usuario');
        }
    }

    async getAllUsers(): Promise<UserWithOutPassword[]> {
        const users = await this.userAuth.getAllUsers();
        console.log('Usuarios obtenidos:', users);
        return users;
    }

    async login(user: UserWithOutId): Promise<UserWithOutPassword | undefined> {
        const loggedInUser = await this.userAuth.login(user);
        if (loggedInUser) {
            console.log('Usuario logueado:', loggedInUser);
        } else {
            console.log('Login fallido');
        }
        return loggedInUser;
    }
}
