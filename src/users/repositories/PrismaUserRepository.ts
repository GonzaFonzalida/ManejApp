import { UserRepository } from "./UserRepository";
import { UserCreate, User, UserUpdate, UserLogin } from "../types";
import prisma from "@config/prismaClient";

class PrismaUserRepository implements UserRepository {

    async register(userData: UserCreate): Promise<User> {
        const user = await prisma.user.create({
            data: userData,
        });
        return user;
    }

    async login(userLogin: UserLogin): Promise<string> {
        const user = await prisma.user.findUnique({
            where: { email: userLogin.email },
        });
        
        return user;
    }

    // async getAll(): Promise<User[]> {
    //     const user = await prisma.user.findMany({
    //         select?:
    //     });
    //     return user;
    // }
}

export default PrismaUserRepository;