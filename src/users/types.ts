export interface UserBase {
    dni: string;
    email: string;
    name: string;
    surname:string
}

export interface UserWithOutId extends UserBase {
    birthDate: any;
    password: string;
}

export interface UserWithOutPassword extends UserBase {
    id: number;
}

export interface User extends UserBase {
    id: number;
    password: string;
}
export interface UserWithDates extends User {
    createdAt: Date;
    birthDate: Date;
    isActive: boolean;
}

export interface UserWithOutPasswordAndDates extends UserBase {
    id: number;
    createdAt: Date;
    birthDate: Date;
    isActive: boolean;
}

export interface UserWithOutIdAndDates extends UserBase {
    password: string;
    createdAt: Date;
    birthDate: Date;
    isActive: boolean;
}
 