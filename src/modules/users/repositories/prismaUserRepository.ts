// C:\Users\thiag\Desktop\Back\ManejApp\src\users\repository\UserPrismaRepository.ts

import { UserWithDates, UserWithOutId, UserWithOutPassword, User, UserWithOutPasswordAndDates } from "../user.types";
import { UserRepository } from "./userRepository";
import { prisma } from "@config/prismaClient";
import { randomUUID } from "crypto";
import bcrypt from "bcryptjs";

export default class UserPrismaRepository implements UserRepository {

    // ... (El método register() y getAllUsers() permanecen igual, sin cambios) ...

    async register({ name, surname, email, dni, password, birthDate, emailVerificationToken, phoneNumber, location }: UserWithDates & { emailVerificationToken?: string; phoneNumber?: string; location?: string }): Promise<UserWithOutPasswordAndDates | Error> {
        // Convertimos la cadena de la fecha a un objeto Date
        const birthDateObject = new Date(birthDate);

        // Crear usuario y Student en una transacción
        const result = await prisma.$transaction(async (tx) => {
            // Crear usuario
            const user = await tx.user.create({
                data: {
                    name: name,
                    surname: surname,
                    email: email.trim().toLowerCase(),
                    dni: dni,
                    password: password,
                    birthDate: birthDateObject,
                    role: 'STUDENT',
                    emailVerificationToken: emailVerificationToken,
                    phoneNumber: phoneNumber,
                    location: location,
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

            // Auto-crear registro Student si el rol es STUDENT
            if (user.role === 'STUDENT') {
                await tx.student.create({
                    data: {
                        userId: user.id
                    }
                });
            }

            return user;
        });

        return result;
    }

    async findByEmail(email: string): Promise<User | undefined> {
        const trimmed = email.trim();
        const lower = trimmed.toLowerCase();
        let row = await prisma.user.findUnique({
            where: { email: lower },
        });
        if (row) return row;
        if (lower !== trimmed) {
            row = await prisma.user.findUnique({
                where: { email: trimmed },
            });
        }
        return row ?? undefined;
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
                phoneNumber: true,
                location: true,
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
                phoneNumber: true,
                location: true,
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

    async updateUser(userId: number, updateData: Partial<UserWithDates>): Promise<UserWithOutPassword | null> {
        // Convertir birthDate si está presente
        const dataToUpdate: any = { ...updateData };
        if (updateData.birthDate) {
            dataToUpdate.birthDate = new Date(updateData.birthDate);
        }

        const user = await prisma.user.update({
            where: { id: userId },
            data: dataToUpdate,
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
                phoneNumber: true,
                location: true,
            },
        });

        return user;
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
                emailVerifiedAt: true,
                phoneNumber: true,
                location: true,
                profileImage: true,
                student: {
                    select: { experienceLevel: true },
                },
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
                emailVerificationToken: true,
            },
        });

        return updatedUser;
    }

    async updateProfileImage(id: number, imagePath: string | null): Promise<UserWithOutPassword | null> {
        const user = await prisma.user.update({
            where: { id },
            data: { profileImage: imagePath } as any,
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

        return user;
    }

    async saveFCMToken(userId: number, fcmToken: string): Promise<void> {
        await prisma.notificationToken.upsert({
            where: { userId },
            update: { token: fcmToken },
            create: { userId, token: fcmToken },
        });
    }

    async deleteFCMToken(userId: number): Promise<void> {
        await prisma.notificationToken.deleteMany({ where: { userId } });
    }

    async getNotificationPreferences(userId: number): Promise<{ emailNotifications: boolean; pushNotifications: boolean } | null> {
        const row = await prisma.user.findUnique({
            where: { id: userId },
            select: { emailNotifications: true, pushNotifications: true },
        });
        if (!row) return null;
        return {
            emailNotifications: row.emailNotifications ?? true,
            pushNotifications: row.pushNotifications ?? true,
        };
    }

    async updateNotificationPreferences(
        userId: number,
        prefs: { emailNotifications?: boolean; pushNotifications?: boolean }
    ): Promise<void> {
        await prisma.user.update({
            where: { id: userId },
            data: prefs as any,
        });
    }

    async createPasswordResetToken(email: string, token: string, expiresAt: Date): Promise<UserWithOutPassword | null> {
        const user = await prisma.user.findUnique({ where: { email } });
        if (!user) return null;
        await prisma.user.update({
            where: { id: user.id },
            data: {
                passwordResetToken: token,
                passwordResetExpiresAt: expiresAt,
            } as any,
        });
        const { password, ...rest } = user;
        return rest as UserWithOutPassword;
    }

    async findUserByPasswordResetToken(token: string): Promise<{ id: number } | null> {
        const user = await prisma.user.findFirst({
            where: {
                passwordResetToken: token,
                passwordResetExpiresAt: { gte: new Date() },
            },
            select: { id: true },
        });
        return user;
    }

    async clearPasswordResetToken(userId: number): Promise<void> {
        await prisma.user.update({
            where: { id: userId },
            data: { passwordResetToken: null, passwordResetExpiresAt: null } as any,
        });
    }

    async findByGoogleId(googleId: string): Promise<User | undefined> {
        const user = await prisma.user.findFirst({
            where: { googleId },
        });
        return user ?? undefined;
    }

    async createGoogleUser(data: { email: string; name: string; surname: string; googleId: string; profileImage?: string }): Promise<User> {
        const randomPassword = randomUUID();
        const hashedPassword = await bcrypt.hash(randomPassword, 10);
        const birthDate = new Date("2000-01-01");
        const dni = `G-${data.googleId}`;

        const user = await prisma.$transaction(async (tx) => {
            const created = await tx.user.create({
                data: {
                    name: data.name,
                    surname: data.surname,
                    email: data.email.trim().toLowerCase(),
                    dni,
                    password: hashedPassword,
                    birthDate,
                    role: "STUDENT",
                    googleId: data.googleId,
                    isActive: true,
                    emailVerifiedAt: new Date(),
                    profileImage: data.profileImage,
                } as any,
            });
            await tx.student.create({ data: { userId: created.id } });
            return created;
        });
        return user;
    }

    async findByAppleSub(appleSub: string): Promise<User | undefined> {
        const user = await prisma.user.findFirst({
            where: { appleSub },
        });
        return user ?? undefined;
    }

    async createAppleUser(data: { email: string; name: string; surname: string; appleSub: string }): Promise<User> {
        const randomPassword = randomUUID();
        const hashedPassword = await bcrypt.hash(randomPassword, 10);
        const birthDate = new Date("2000-01-01");
        const dni = `A-${data.appleSub}`;

        const user = await prisma.$transaction(async (tx) => {
            const created = await tx.user.create({
                data: {
                    name: data.name,
                    surname: data.surname,
                    email: data.email.trim().toLowerCase(),
                    dni,
                    password: hashedPassword,
                    birthDate,
                    role: "STUDENT",
                    appleSub: data.appleSub,
                    isActive: true,
                    emailVerifiedAt: new Date(),
                } as any,
            });
            await tx.student.create({ data: { userId: created.id } });
            return created;
        });
        return user;
    }

    async updateStudentExperienceLevel(userId: number, experienceLevel: number): Promise<{ experienceLevel: number } | null> {
        const user = await prisma.user.findUnique({ where: { id: userId }, select: { id: true, role: true } });
        if (!user || user.role !== "STUDENT") return null;
        return prisma.student.upsert({
            where: { userId },
            create: { userId, experienceLevel },
            update: { experienceLevel },
            select: { experienceLevel: true },
        });
    }
}
