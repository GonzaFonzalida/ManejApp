import {  UserWithOutId, User, UserWithOutPassword } from "../types";
import {UserRepository} from "./userRepository"
import { prisma } from "../../config/prismaClient";

class UserPrismaRepository implements UserRepository {

    async register(user: UserWithOutId): Promise<UserWithOutPassword> {

        return await prisma.user.create({
            data: {
                dni: user.dni,
                email: user.email,
                password: user.password,
                // Agregado: estos campos son necesarios para la creación del usuario.
                name: user.name, 
                surname: user.surname, 
                birthDate: new Date(user.birthDate) // Asegúrate de que birthDate sea un objeto Date
            },
            select: {
                id: true,
                dni: true,
                email: true,
                // Agregado: selecciona los campos para que coincidan con UserWithOutPassword
                name: true, 
                surname: true, 
                birthDate: true
            }
        });
    }

    async getAllUsers(): Promise<User[]> {
        return await prisma.user.findMany();
    }

    async login(user: UserWithOutId): Promise<UserWithOutPassword | undefined> {
        return await prisma.user.findFirst({
            where: {
                OR: [
                    { email: user.email },
                    { dni: user.dni }
                ]
            },
            select: {
                id: true,
                dni: true,
                email: true,
                // Agregado: selecciona los campos para que coincidan con UserWithOutPassword
                name: true, 
                surname: true, 
                birthDate: true
            }
        }) ?? undefined;
    }

}

export default UserPrismaRepository;
