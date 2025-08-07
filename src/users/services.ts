import PrismaUserRepository from "./repositories/PrismaUserRepository";
import { UserRepository } from "./repositories/UserRepository";
import { User, UserCreate, UserLogin } from "./types";


export default class UserService{
    private userRepository: PrismaUserRepository;

    constructor(userRepository: PrismaUserRepository) {
        this.userRepository = userRepository;
    }

    async login(userData:UserLogin) {
        return this.userRepository.login(userData);
    }

    async register(userData:UserCreate) {
        return this.userRepository.register(userData)
    }

    
}