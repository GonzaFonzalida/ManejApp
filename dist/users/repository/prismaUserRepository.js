"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const prismaClient_1 = require("../../config/prismaClient");
class UserPrismaRepository {
    async register(user) {
        return await prismaClient_1.prisma.user.create({
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
    async getAllUsers() {
        return await prismaClient_1.prisma.user.findMany();
    }
    async login(user) {
        return await prismaClient_1.prisma.user.findFirst({
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
exports.default = UserPrismaRepository;
