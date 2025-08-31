"use strict";
// C:\Users\thiag\Desktop\Back\ManejApp\src\users\repository\UserPrismaRepository.ts
Object.defineProperty(exports, "__esModule", { value: true });
const prismaClient_1 = require("../../config/prismaClient");
class UserPrismaRepository {
    // ... (El método register() y getAllUsers() permanecen igual, sin cambios) ...
    async register({ name, surname, email, dni, password, birthDate }) {
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
                birthDate: birthDateObject,
                role: 'STUDENT',
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
                role: true,
            }
        });
    }
    async findByEmail(email) {
        return await prismaClient_1.prisma.user.findUnique({
            where: { email }
        }) ?? undefined;
    }
    async getAllUsers() {
        return await prismaClient_1.prisma.user.findMany({
            select: {
                id: true,
                dni: true,
                email: true,
                name: true,
                surname: true,
                role: true,
            }
        });
    }
    async findByRole(rol) {
        return await prismaClient_1.prisma.user.findMany({
            where: {
                role: rol,
            },
            select: {
                id: true,
                dni: true,
                email: true,
                name: true,
                surname: true,
                role: true,
                createdAt: true,
                birthDate: true,
                isActive: true,
            },
        });
    }
    async updateLastLoginAt(userId) {
        const user = await prismaClient_1.prisma.user.update({
            where: { id: userId },
            data: {
                lastLoginAt: new Date(), // se actualiza con la fecha actual
            },
        });
        // Omitimos la contraseña antes de devolver
        const { password, ...userWithoutPassword } = user;
        return userWithoutPassword;
    }
    async findUser(value) {
        let whereClause;
        if (typeof value === "number" || /^\d+$/.test(value)) {
            // Si es número o string numérico, buscar por ID
            whereClause = { id: typeof value === "number" ? value : parseInt(value, 10) };
        }
        else {
            // Si es string no numérico, buscar por DNI o email
            whereClause = { OR: [{ dni: value }, { email: value }] };
        }
        const foundUser = await prismaClient_1.prisma.user.findFirst({
            where: whereClause,
            select: {
                id: true,
                dni: true,
                email: true,
                name: true,
                surname: true,
                role: true,
                createdAt: true,
                birthDate: true,
                isActive: true,
            },
        });
        return foundUser ?? undefined;
    }
    async login(user) {
        const foundUser = await prismaClient_1.prisma.user.findFirst({
            where: {
                OR: [
                    { email: user.email },
                    { dni: user.dni }
                ],
                AND: {
                    password: user.password
                }
            }
        });
        if (!foundUser) {
            // Si no se encuentra el usuario, retornamos undefined.
            return undefined;
        }
        const passwordsMatch = foundUser.password === user.password;
        if (!passwordsMatch) {
            // Si las contraseñas no coinciden, retornamos undefined.
            return undefined;
        }
        // 3. Si el usuario existe y la contraseña es correcta, devolvemos el usuario
        // sin la contraseña para mantener la seguridad.
        return {
            id: foundUser.id,
            dni: foundUser.dni,
            email: foundUser.email,
            name: foundUser.name,
            surname: foundUser.surname,
            role: foundUser.role
        };
    }
}
exports.default = UserPrismaRepository;
