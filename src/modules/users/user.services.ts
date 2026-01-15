import { UserWithOutPassword, UserWithDates, UserWithOutId } from "./user.types";
import { UserRepository } from "./repositories/userRepository";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { JWT_SECRET } from "@config/config";
import EmailService from "@shared/services/EmailService";
import { randomUUID } from "crypto";

export default class UserService {
    constructor(private userAuth: UserRepository, private emailService: EmailService) {}

    async register(user: UserWithDates): Promise<UserWithOutPassword | Error> {
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

            // Enviar email de verificación
            try {
                await this.emailService.sendVerificationEmail(user.email, verificationToken);
            } catch (emailError) {
                console.error('Error sending verification email:', emailError);
                // No fallar el registro por error en email, pero loggear
            }

            return result;

        } catch (error: any) {
            return error as Error;
        }
    }

    async getUserById(value: string): Promise<UserWithOutPassword | undefined> {
        return await this.userAuth.findUser(value);
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
}
