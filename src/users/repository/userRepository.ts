export interface UserBase {
    username: string;
    email: string;
}

export interface UserWithOutId extends UserBase {
    password: string;
}

export interface UserWithOutPassword extends UserBase {
    id: number;
}

export interface User extends UserBase {
    id: number;
    password: string;
}



export interface UserRepository {
    getAllUsers(): Promise<UserWithOutPassword[]>;
    login(user: UserWithOutId): Promise<UserWithOutPassword | undefined>;
    register(user: UserWithOutId): Promise<UserWithOutPassword | Error>;
}