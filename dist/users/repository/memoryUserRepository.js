"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class userMemoryRepository {
    users = [
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
    register(user) {
        const { id, dni, email, name, surname } = user;
        this.users.push(user);
        return Promise.resolve(user);
    }
    login(user) {
        const foundUser = this.users.find(u => u.email === user.email || u.dni === user.dni);
        return Promise.resolve(foundUser);
    }
    getAllUsers() {
        return Promise.resolve(this.users);
    }
}
const instance = new userMemoryRepository();
exports.default = userMemoryRepository;
