import {  UserWithOutId, User, UserWithOutPassword } from "../types";
import {UserRepository} from "./userRepository"
import { prisma } from "../../config/prismaClient";

class UserPrismaRepository implements UserRepository {

    async register(user: UserWithOutId): Promise<UserWithOutPassword> {

        return await prisma.user.create({
            data: {
                dni: user.dni,
                email: user.email,
                password: user.password
            },
            select: {
                id: true,
                dni: true,
                email: true
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
                email: true
            }
        }) ?? undefined;
    }

}

export default UserPrismaRepository;

