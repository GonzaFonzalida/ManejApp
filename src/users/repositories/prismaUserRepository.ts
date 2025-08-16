// C:\Users\thiag\Desktop\Back\ManejApp\src\users\repository\UserPrismaRepository.ts

import { UserWithDates, UserWithOutId, UserWithOutPassword, UserWithOutPasswordAndDates } from "../user.types";
import { UserRepository } from "./userRepository"
import { prisma } from "../../config/prismaClient";

export default class UserPrismaRepository implements UserRepository {

    // ... (El método register() y getAllUsers() permanecen igual, sin cambios) ...

    async register({name, surname, email, dni, password, birthDate}: UserWithDates): Promise<UserWithOutPasswordAndDates> {
        // Convertimos la cadena de la fecha a un objeto Date
        const birthDateObject = new Date(birthDate);

        // Pasamos un objeto 'data' limpio y explícito para evitar conflictos.
        return await prisma.user.create({
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

    async getAllUsers(): Promise<UserWithOutPassword[]> {
        return await prisma.user.findMany({
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

    async findUser(value: string): Promise<UserWithOutPassword | undefined> {
        const foundUser = await prisma.user.findFirst({
        where: /^\d+$/.test(value)
        ? { id: parseInt(value, 10) }
        : { OR: [{ dni: value }, { email: value }] },
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

    async login(user: UserWithOutId): Promise<UserWithOutPassword | undefined> {
        const foundUser = await prisma.user.findFirst({
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
