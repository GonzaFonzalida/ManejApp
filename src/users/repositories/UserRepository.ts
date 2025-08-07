import  {UserCreate, User, UserUpdate, UserLogin}  from "../types";

export interface UserRepository{
    register(userData: UserCreate): Promise<User> ;
    login(userData: UserLogin):Promise <string> ; 
    // getAll(): Promise<User[]> ; 
    // getId(id: number): Promise<User | undefined> ;
}
