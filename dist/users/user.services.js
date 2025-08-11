"use strict";
// C:\Users\thiag\Desktop\Back\ManejApp\src\users\user.services.ts
Object.defineProperty(exports, "__esModule", { value: true });
class UserService {
    userAuth;
    constructor(userAuth) {
        this.userAuth = userAuth;
    }
    // La firma del método ahora devuelve un objeto de tipo `UserWithOutId` o un `Error`.
    async register(user) {
        try {
            // El repositorio devolverá un objeto con la propiedad 'id' si el registro es exitoso.
            const result = await this.userAuth.register(user);
            if (result instanceof Error) {
                return result;
            }
            // Verifica que el resultado tenga la propiedad 'password'
            if ('password' in result) {
                return result;
            }
            return new Error("Returned user object does not have required 'password' property.");
        }
        catch (error) {
            // Si ocurre un error, lo devolvemos como un objeto Error para que
            // el controlador lo maneje adecuadamente.
            return error;
        }
    }
    async getAllUsers() {
        return await this.userAuth.getAllUsers();
    }
    async login(user) {
        return await this.userAuth.login(user);
    }
}
exports.default = UserService;
