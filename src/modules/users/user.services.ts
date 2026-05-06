import { UserWithOutPassword, UserWithDates, UserWithOutId } from "./user.types";
import { UserRepository } from "./repositories/userRepository";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { JWT_SECRET } from "@config/config";
import EmailService from "@shared/services/EmailService";
import FileService from "@shared/services/FileService";
import { randomUUID } from "crypto";
import CustomizedError from "@classes/CustomizedError";
import { prisma } from "@config/prismaClient";
import { Prisma } from "@prisma/client";
import fs from "fs/promises";
import path from "path";

export default class UserService {
    constructor(private userAuth: UserRepository, private emailService: EmailService) {}

    async register(user: UserWithDates): Promise<{ user: UserWithOutPassword; accessToken?: string } | Error> {
        try {
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash(user.password, salt);
            const verificationToken = randomUUID();

            const result = await this.userAuth.register({
                ...user,
                password: hashedPassword,
                emailVerificationToken: verificationToken,
            } as any);

            if (result instanceof Error) {
                return result;
            }

            const appUrl = process.env.APP_URL || 'http://localhost:3099';
            const verificationUrl = `${appUrl}/api/v1/users/verify-email/${verificationToken}`;
            const devAutoVerify = process.env.NODE_ENV === 'development' && process.env.DEV_AUTO_VERIFY_EMAIL === 'true';

            let accessToken: string | undefined;
            if (devAutoVerify) {
                await this.userAuth.verifyEmail(verificationToken);
                const verifiedUser = await this.userAuth.findUser((result as any).id);
                if (verifiedUser) {
                    accessToken = jwt.sign(
                        { id: verifiedUser.id, role: verifiedUser.role },
                        JWT_SECRET,
                        { expiresIn: "1h" }
                    );
                }
                console.log('[DEV] Email verificado automáticamente. Usuario logueado.');
            } else {
                try {
                    await this.emailService.sendVerificationEmail(user.email, verificationToken);
                } catch (emailError) {
                    console.error('Error enviando email de verificación:', emailError);
                    console.log('\n--- PARA VERIFICAR MANUALMENTE (copiá y abrí en el navegador): ---');
                    console.log(verificationUrl);
                    console.log('----------------------------------------------------------------\n');
                }
            }

            return { user: result, accessToken };

        } catch (error: any) {
            return error as Error;
        }
    }

    async getUserById(value: string): Promise<UserWithOutPassword | undefined> {
        return await this.userAuth.findUser(value);
    }

    async updateStudentExperienceLevel(userId: number, experienceLevel: number): Promise<{ experienceLevel: number } | null> {
        return this.userAuth.updateStudentExperienceLevel(userId, experienceLevel);
    }

    async updateUser(userId: number, updateData: Partial<UserWithDates>): Promise<UserWithOutPassword | null> {
        // Si se está actualizando la contraseña, hashearla
        if (updateData.password) {
            const salt = await bcrypt.genSalt(10);
            updateData.password = await bcrypt.hash(updateData.password, salt);
        }

        return await this.userAuth.updateUser(userId, updateData);
    }

    async findByRole(role: string): Promise<UserWithOutPassword[]> {
        return await this.userAuth.findByRole(role);
    }

    async getAllUsers(): Promise<UserWithOutPassword[]> {
        return await this.userAuth.getAllUsers();
    }

    async login(user: { email: string; password: string }): Promise<{ token: string } | Error> {
        const foundUser = await this.userAuth.findByEmail(user.email);

        if (!foundUser) {
            return new Error("Usuario no encontrado");
        }

        const isPasswordValid = await bcrypt.compare(user.password, foundUser.password);
        if (!isPasswordValid) {
            return new Error("Contraseña incorrecta");
        }

        // Verificar si el email está verificado
        if (!(foundUser as any).emailVerifiedAt) {
            return new Error("Por favor verifica tu email antes de iniciar sesión");
        }

        const token = jwt.sign(
            { id: foundUser.id, role: foundUser.role },
            JWT_SECRET,
            { expiresIn: "1h" }
        );

        return { token };
    }

    async verifyEmail(token: string): Promise<UserWithOutPassword | null> {
        return await this.userAuth.verifyEmail(token);
    }

    async resendVerificationEmail(email: string): Promise<UserWithOutPassword | null> {
        const user = await this.userAuth.resendVerificationToken(email);
        if (user) {
            try {
                await this.emailService.sendVerificationEmail(email, (user as any).emailVerificationToken);
            } catch (emailError) {
                console.error('Error sending verification email:', emailError);
            }
        }
        return user;
    }

    async updateProfileImage(userId: number, imagePath: string): Promise<UserWithOutPassword | null> {
        // Get current user to check if there's an existing image
        const currentUser = await this.userAuth.findUser(userId);
        if (currentUser && (currentUser as any).profileImage) {
            // Delete old profile image
            await FileService.deleteFile((currentUser as any).profileImage);
        }

        // Update user with new image path
        return await this.userAuth.updateProfileImage(userId, imagePath);
    }

    async deleteProfileImage(userId: number): Promise<UserWithOutPassword | null> {
        // Get current user
        const user = await this.userAuth.findUser(userId);
        if (user && (user as any).profileImage) {
            // Delete the image file
            await FileService.deleteFile((user as any).profileImage);

            // Remove image path from database
            return await this.userAuth.updateProfileImage(userId, null);
        }
        return user as UserWithOutPassword;
    }

    async getProfileImagePath(userId: number): Promise<string | null> {
        const user = await this.userAuth.findUser(userId);
        return user ? (user as any).profileImage : null;
    }

    async saveFCMToken(userId: number, fcmToken: string): Promise<void> {
        await this.userAuth.saveFCMToken(userId, fcmToken);
    }

    async deleteFCMToken(userId: number): Promise<void> {
        await this.userAuth.deleteFCMToken(userId);
    }

    async getNotificationPreferences(userId: number) {
        return this.userAuth.getNotificationPreferences(userId);
    }

    async updateNotificationPreferences(
        userId: number,
        prefs: { emailNotifications?: boolean; pushNotifications?: boolean }
    ): Promise<void> {
        await this.userAuth.updateNotificationPreferences(userId, prefs);
    }

    async forgotPassword(email: string): Promise<{ ok: boolean; message: string }> {
        const user = await this.userAuth.findByEmail(email);
        if (!user) {
            return { ok: true, message: "Si el email existe, recibirás un enlace para restablecer tu contraseña." };
        }
        const token = randomUUID();
        const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hora
        await this.userAuth.createPasswordResetToken(email, token, expiresAt);
        const appUrl = process.env.APP_URL || "http://localhost:3099";
        const resetUrl = `${appUrl}/api/v1/users/reset-password?token=${token}`;
        const devSkipEmail = process.env.NODE_ENV === "development" && process.env.DEV_AUTO_VERIFY_EMAIL === "true";
        if (devSkipEmail) {
            console.log("\n--- [DEV] Link para restablecer contraseña (copiá y abrí): ---");
            console.log(resetUrl);
            console.log("----------------------------------------------------------------\n");
        } else {
            try {
                await this.emailService.sendPasswordResetEmail(email, token);
            } catch (err) {
                console.error("Error enviando email de reset:", err);
                console.log("\n--- Link de respaldo: ---\n", resetUrl);
            }
        }
        return { ok: true, message: "Si el email existe, recibirás un enlace para restablecer tu contraseña." };
    }

    async resetPassword(token: string, newPassword: string): Promise<{ ok: boolean; message: string }> {
        const user = await this.userAuth.findUserByPasswordResetToken(token);
        if (!user) {
            return { ok: false, message: "El enlace ha expirado o es inválido. Solicitá uno nuevo." };
        }
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);
        await this.userAuth.updateUser(user.id, { password: hashedPassword } as any);
        await this.userAuth.clearPasswordResetToken(user.id);
        return { ok: true, message: "Contraseña actualizada. Ya podés iniciar sesión." };
    }

    async deleteMyAccount(
        userId: number,
        body: { confirmPhrase: string; password?: string },
    ): Promise<void | CustomizedError> {
        if (body.confirmPhrase !== "ELIMINAR") {
            return new CustomizedError("Debés escribir ELIMINAR para confirmar", 400);
        }

        const user = await prisma.user.findUnique({
            where: { id: userId },
            include: { instructor: true },
        });
        if (!user) {
            return new CustomizedError("Usuario no encontrado", 404);
        }
        if (user.accountDeletedAt != null) {
            return new CustomizedError("La cuenta ya fue eliminada", 400);
        }
        if (user.role === "ADMIN") {
            return new CustomizedError("Los administradores no pueden eliminar la cuenta desde la app", 403);
        }

        const hasGoogle = user.googleId != null && user.googleId !== "";
        const hasApple = user.appleSub != null && user.appleSub !== "";
        if (!hasGoogle && !hasApple) {
            const pwd = body.password?.trim() ?? "";
            if (!pwd) {
                return new CustomizedError("Contraseña requerida", 400);
            }
            const ok = await bcrypt.compare(pwd, user.password);
            if (!ok) {
                return new CustomizedError("Contraseña incorrecta", 401);
            }
        }

        const pathsToUnlink: string[] = [];
        if (user.profileImage) {
            pathsToUnlink.push(user.profileImage);
        }
        const inst = user.instructor;
        if (inst) {
            for (const key of ["dobleComandoImg", "seguroImg", "vtvImg", "reincidenciaImg", "licenciaImg"] as const) {
                const v = inst[key];
                if (v) {
                    pathsToUnlink.push(v);
                }
            }
            if (inst.photos != null && Array.isArray(inst.photos)) {
                for (const p of inst.photos) {
                    if (typeof p === "string" && p.length > 0) {
                        pathsToUnlink.push(p);
                    }
                }
            }
        }

        const uuid = randomUUID();
        const placeholderEmail = `deleted+${uuid}@deleted.local`;
        const placeholderDni = `DEL-${uuid}`;
        const randomPass = await bcrypt.hash(randomUUID(), 10);

        await prisma.$transaction(async (tx) => {
            await tx.session.deleteMany({ where: { userId } });
            await tx.notificationToken.deleteMany({ where: { userId } });
            await tx.message.updateMany({
                where: { senderId: userId },
                data: { content: "[Contenido eliminado]" },
            });

            await tx.user.update({
                where: { id: userId },
                data: {
                    name: "Usuario",
                    surname: "Eliminado",
                    email: placeholderEmail,
                    dni: placeholderDni,
                    password: randomPass,
                    googleId: null,
                    appleSub: null,
                    isActive: false,
                    accountDeletedAt: new Date(),
                    profileImage: null,
                    phoneNumber: null,
                    location: null,
                    emailVerificationToken: null,
                    passwordResetToken: null,
                    passwordResetExpiresAt: null,
                    emailNotifications: false,
                    pushNotifications: false,
                },
            });

            if (inst) {
                await tx.instructor.update({
                    where: { userId },
                    data: {
                        mpAccessToken: null,
                        mpCollectorId: null,
                        dobleComandoImg: null,
                        seguroImg: null,
                        vtvImg: null,
                        reincidenciaImg: null,
                        licenciaImg: null,
                        bio: null,
                        photos: Prisma.DbNull,
                        addressText: null,
                    },
                });
            }
        });

        for (const p of pathsToUnlink) {
            await UserService.unlinkStoredUploadPath(p);
        }
    }

    private static async unlinkStoredUploadPath(stored: string): Promise<void> {
        const s = stored.trim();
        if (!s || s.startsWith("http://") || s.startsWith("https://")) {
            return;
        }
        const base = path.basename(s);
        const candidates = [
            path.join(process.cwd(), "uploads", "profiles", base),
            path.join(process.cwd(), "uploads", "profile-images", base),
        ];
        if (path.isAbsolute(s)) {
            candidates.unshift(s);
        }
        for (const full of candidates) {
            try {
                await fs.unlink(full);
                break;
            } catch {
                /* siguiente candidato */
            }
        }
    }
}
