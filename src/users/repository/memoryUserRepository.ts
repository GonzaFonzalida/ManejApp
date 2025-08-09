import { UserRepository, User, UserWithOutPassword } from "./userRepository";


class userMemoryRepository implements UserRepository {
    private users: UserWithOutPassword[] = [
        {
            id: 1,
            username: "manuelito",
            email: "manueltito@gmail.com",
        },
        {
            id: 2,
            username: "juanito",
            email: "juanito@gmail.com",

        },
        {
            id: 3,
            username: "pedrito",
            email: "pedrito@gmail.com",

        }
    ];
    register(user: User): Promise<UserWithOutPassword | Error> {
        const userSimulated: User = {
            id: 45,
            username: "example",
            password: "pass22234",
            email: "example@gmail.com"
        }
        this.users.push(userSimulated);
        return Promise.resolve(userSimulated)

    }
    getAllUsers(): Promise<UserWithOutPassword[]> {
        return Promise.resolve(this.users);
    }

    getUserById(id: number): Promise<UserWithOutPassword | undefined> {
        return Promise.resolve(this.users.find(user => user.id === id));
    }
}

const instance = new userMemoryRepository();

export default userMemoryRepository;