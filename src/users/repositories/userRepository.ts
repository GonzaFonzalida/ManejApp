import { ZodEmail } from "zod";
import {UserWithOutPassword, UserWithOutPasswordAndDates, UserWithOutId, UserWithDates } 
from "../user.types";


export interface UserRepository {
    getAllUsers(): Promise<UserWithOutPassword[]>;
    login(user: UserWithOutId): Promise<UserWithOutPassword | undefined>;
    register(user: UserWithDates): Promise<UserWithOutPasswordAndDates>;
    findUser(value: string):  Promise<UserWithOutPassword | undefined>;
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

