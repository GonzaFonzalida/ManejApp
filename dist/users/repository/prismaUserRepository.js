"use strict";
// C:\Users\thiag\Desktop\Back\ManejApp\src\users\repository\UserPrismaRepository.ts
Object.defineProperty(exports, "__esModule", { value: true });
const prismaClient_1 = require("../../config/prismaClient");
class UserPrismaRepository {
    async register(user) {
        // Extraemos las propiedades necesarias para Prisma
        const { name, surname, email, dni, password, birthDate } = user;
        // Convertimos la cadena de la fecha a un objeto Date
        const birthDateObject = new Date(birthDate);
        // Pasamos un objeto 'data' limpio y explícito para evitar conflictos.
        return await prismaClient_1.prisma.user.create({
            data: {
                name: name,
                surname: surname,
                email: email,
                dni: dni,
                password: password,
                birthDate: birthDateObject, // Pasamos el objeto Date directamente
            },
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
    async getAllUsers() {
        return await prismaClient_1.prisma.user.findMany({
            select: {
                id: true,
                dni: true,
                email: true,
                name: true,
                surname: true,
            }
        });
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
                email: true,
                name: true,
                surname: true,
            }
        }) ?? undefined;
    }
}
exports.default = UserPrismaRepository;
