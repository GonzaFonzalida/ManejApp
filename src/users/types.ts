export interface UserBase{
    name: string ;
    surname: string ; 
    email: string ; 
    dni: string ;
    createdAt: Date ;
    updatedAt: Date ;
}

export interface UserLogin{
    email: string ; 
    dni?: string ;
    password: string ; 
}

export interface User extends UserBase {
    id: string;
    isActive: boolean;
}

export interface UserCreate extends Omit<UserBase, 'createdAt' | 'updatedAt'> {
    password: string;
}

export interface UserUpdate extends Partial<Omit<UserBase, 'createdAt' | 'updatedAt'>> {
    password?: string;
}

 