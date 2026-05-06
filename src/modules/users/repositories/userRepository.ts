import { ZodEmail } from "zod";
import {UserWithOutPassword, UserWithOutPasswordAndDates, User, UserWithOutId, UserWithDates } 
from "../user.types";


export interface UserRepository {
    getAllUsers(): Promise<UserWithOutPassword[]>;
    login(user: UserWithOutId): Promise<UserWithOutPassword | undefined>;
    register(user: UserWithDates): Promise<UserWithOutPasswordAndDates | Error>;
    findUser(value: string | number):  Promise<UserWithOutPassword | undefined>;
    findByRole(rol: string): Promise<UserWithOutPassword[]>;
    findByEmail(email: string): Promise<User | undefined>;
    updateUser(id: number, updateData: Partial<UserWithDates>): Promise<UserWithOutPassword | null>;
    updateLastLoginAt(id: number): Promise<UserWithOutPassword | null>;
    verifyEmail(token: string): Promise<UserWithOutPassword | null>;
    resendVerificationToken(email: string): Promise<UserWithOutPassword | null>;
    updateRole(id: number, role: string): Promise<UserWithOutPassword | null>;
    updateProfileImage(id: number, imagePath: string | null): Promise<UserWithOutPassword | null>;
    saveFCMToken(userId: number, fcmToken: string): Promise<void>;
    createPasswordResetToken(email: string, token: string, expiresAt: Date): Promise<UserWithOutPassword | null>;
    findUserByPasswordResetToken(token: string): Promise<{ id: number } | null>;
    clearPasswordResetToken(userId: number): Promise<void>;
    findByGoogleId(googleId: string): Promise<User | undefined>;
    createGoogleUser(data: { email: string; name: string; surname: string; googleId: string; profileImage?: string }): Promise<User>;
    findByAppleSub(appleSub: string): Promise<User | undefined>;
    createAppleUser(data: { email: string; name: string; surname: string; appleSub: string }): Promise<User>;
    updateStudentExperienceLevel(userId: number, experienceLevel: number): Promise<{ experienceLevel: number } | null>;
    getNotificationPreferences(userId: number): Promise<{ emailNotifications: boolean; pushNotifications: boolean } | null>;
    updateNotificationPreferences(
        userId: number,
        prefs: { emailNotifications?: boolean; pushNotifications?: boolean }
    ): Promise<void>;
    deleteFCMToken(userId: number): Promise<void>;
}

// model User {
//   id             Int       @id @default(autoincrement())
//   name           String     
//   surname        String
//   email          String    @unique
//   password       String
//   dni            String    @unique
//   createdAt      DateTime  @default(now())
//   birthDate      DateTime  @db.Date
//   isActive       Boolean   @default(true)
// }

