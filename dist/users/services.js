"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class UserService {
    userAuth;
    constructor(userAuth) {
        this.userAuth = userAuth;
    }
    async register(user) {
        console.log(this.userAuth.register(user));
        return await this.userAuth.register(user);
    }
    async getAllUsers() {
        console.log(this.userAuth.getAllUsers());
        return await this.userAuth.getAllUsers();
    }
    async login(user) {
        console.log(this.userAuth.login(user));
        return await this.userAuth.login(user);
    }
}
exports.default = UserService;
