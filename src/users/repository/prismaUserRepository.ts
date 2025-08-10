import {UserWithDates,UserWithOutId, User, UserWithOutPassword, UserWithOutPasswordAndDates } from "../user.types";
import {UserRepository} from "./userRepository"
import { prisma } from "../../config/prismaClient";

export default class UserPrismaRepository implements UserRepository {

    async register(user: UserWithDates): Promise<UserWithOutPasswordAndDates> {
        const {dni, email, password, birthDate, isActive, createdAt} = user;
        return await prisma.user.create({
            data: user,
            select: {
                id: true,
                dni: true,
                email: true,
                name: true,
                surname: true,
                birthDate: true,
                isActive: true,
                createdAt: true,
            }
        });
    }

    async getAllUsers(): Promise<UserWithOutPassword[]> {
        return await prisma.user.findMany({
            select: {
                id: true,
                dni: true,
                email: true,
                name: true,
                surname: true,
            }
        });
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
                name: true,
                surname: true,
            }
        }) ?? undefined;
    }

}


