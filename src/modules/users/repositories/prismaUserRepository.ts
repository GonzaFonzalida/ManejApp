// C:\Users\thiag\Desktop\Back\ManejApp\src\users\repository\UserPrismaRepository.ts

import { UserWithDates, UserWithOutId, UserWithOutPassword, User, UserWithOutPasswordAndDates } from "../user.types";
import { UserRepository } from "./userRepository"
import { prisma } from "@config/prismaClient";
import { error } from "console";
import { randomUUID } from "crypto";

export default class UserPrismaRepository implements UserRepository {

    // ... (El método register() y getAllUsers() permanecen igual, sin cambios) ...

    async register({name, surname, email, dni, password, birthDate, emailVerificationToken}: UserWithDates & { emailVerificationToken?: string }): Promise<UserWithOutPasswordAndDates | Error> {
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
                emailVerificationToken: emailVerificationToken,
            } as any,
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

    async findByEmail(email: string): Promise<User | undefined> {
        return await prisma.user.findUnique({
            where : {email}
        }) ?? undefined;
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

   async findByRole(rol: string): Promise<UserWithOutPassword[]> {
    return await prisma.user.findMany({
        where: {
        role: rol as any, 
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

    async updateLastLoginAt(userId: number): Promise<UserWithOutPassword | null> {
        const user = await prisma.user.update({
        where: { id: userId },
        data: {
            lastLoginAt: new Date(), // se actualiza con la fecha actual
        },
        });

        // Omitimos la contraseña antes de devolver
        const { password, ...userWithoutPassword } = user;
        return userWithoutPassword;
    }

    async updateRole(userId: number, role: string): Promise<UserWithOutPassword | null> {
        const user = await prisma.user.update({
            where: { id: userId },
            data: { role: role as any },
        });

        // Omitimos la contraseña antes de devolver
        const { password, ...userWithoutPassword } = user;
        return userWithoutPassword;
    }

    async findUser(value: string | number): Promise<UserWithOutPassword | undefined> {
  let whereClause;

  if (typeof value === "number" || /^\d+$/.test(value)) {
    // Si es número o string numérico, buscar por ID
    whereClause = { id: typeof value === "number" ? value : parseInt(value, 10) };
  } else {
    // Si es string no numérico, buscar por DNI o email
    whereClause = { OR: [{ dni: value }, { email: value }] };
  }

  const foundUser = await prisma.user.findFirst({
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

    async verifyEmail(token: string): Promise<UserWithOutPassword | null> {
        const user = await prisma.user.findUnique({
            where: { emailVerificationToken: token } as any,
        });

        if (!user) {
            return null;
        }

        // Verificar y actualizar
        const updatedUser = await prisma.user.update({
            where: { id: user.id },
            data: {
                emailVerifiedAt: new Date(),
                emailVerificationToken: null, // Limpiar token
                isActive: true, // Activar cuenta
            } as any,
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

        return updatedUser;
    }

    async resendVerificationToken(email: string): Promise<UserWithOutPassword | null> {
        const user = await prisma.user.findUnique({
            where: { email },
        });

        if (!user || (user as any).emailVerifiedAt) {
            return null; // Ya verificado o no existe
        }

        const newToken = randomUUID();

        const updatedUser = await prisma.user.update({
            where: { id: user.id },
            data: { emailVerificationToken: newToken } as any,
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

        return updatedUser;
    }
}
