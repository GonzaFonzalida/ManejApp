import { UserRepository, UserWithOutId, User, UserWithOutPassword } from "./userRepository";
import { prisma } from "../../config/prismaClient";
class UserPrismaRepository implements UserRepository {

    async register(user: UserWithOutId): Promise<UserWithOutPassword> {

        return await prisma.user.create({
            data: {
                username: user.username,
                email: user.email,
                password: user.password
            },
            select: {
                id: true,
                username: true,
                email: true
            }
        });
    }

    async getAllUsers(): Promise<User[]> {
        return await prisma.user.findMany();
    }

    async getUserById(id: number): Promise<UserWithOutPassword | undefined> {
        return await prisma.user.findUnique({
            where: { id },
            select: {
                id: true,
                username: true,
                email: true
            }
        }) ?? undefined;
    }

}

export default UserPrismaRepository;

