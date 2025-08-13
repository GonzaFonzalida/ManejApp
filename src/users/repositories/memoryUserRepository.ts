import {User, UserWithOutId, UserWithDates, UserWithOutPassword, UserWithOutPasswordAndDates } 
from "../user.types"
import {UserRepository} from "./userRepository";


class userMemoryRepository implements UserRepository {
    private users: UserWithOutPassword[] = [
        {  
            id: 1,
            dni: "23.343.343",
            email: "manuadangonzales@gmail.com",
            name: "manuel",
            surname: "gonzalez"
        },
        {
            id: 2,
            dni: "45.678.910",
            email: "lucia.perez@example.com",
            name: "lucia",
            surname: "perez"
        },
        {
            id: 3,
            dni: "12.345.678",
            email: "juan.lopez@example.com",
            name: "juan",
            surname: "lopez"
        }
    ];
    register(user: UserWithDates): Promise<UserWithOutPasswordAndDates | Error> {
        const {id, dni, email, name, surname} = user;
        
        this.users.push(user);
        
        return Promise.resolve(user)
    }
    
    login(user: UserWithOutId): Promise<UserWithOutPassword | undefined> {
        const foundUser = this.users.find(
            u => u.email === user.email || u.dni === user.dni
        );
        return Promise.resolve(foundUser);
    }
    getAllUsers(): Promise<UserWithOutPassword[]> {
        return Promise.resolve(this.users);
    }

    
}

const instance = new userMemoryRepository();

export default userMemoryRepository;