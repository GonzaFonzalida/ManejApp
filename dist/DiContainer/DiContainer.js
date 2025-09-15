"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class DiContainer {
    services;
    singletons;
    constructor() {
        this.services = new Map();
        this.singletons = new Map();
    }
    register(name, implementation, dependencies = []) {
        console.log(`Registering service: ${name}`);
        this.services.set(name, {
            implementation,
            dependencies,
            singleton: false
        });
    }
    registerSingleton(name, implementation, dependencies) {
        this.services.set(name, {
            implementation,
            dependencies,
            singleton: true
        });
    }
    registerInstance(name, instance) {
        this.singletons.set(name, instance);
    }
    resolve(name) {
        console.log(`Resolving service: ${name}`);
        if (this.singletons.has(name)) {
            return this.singletons.get(name);
        }
        const services = this.services.get(name);
        if (!services) {
            throw new Error(`el servicio es requerido ${name}`);
        }
        const dependencies = services.dependencies.map((dep) => this.resolve(dep));
        const instance = new services.implementation(...dependencies);
        if (services.singleton && !this.singletons.has(name)) {
            this.singletons.set(name, instance);
        }
        return instance;
    }
}
exports.default = DiContainer;
// class Logger {
//     log(message: string) {
//         console.log('Logger:', message);
//     }
// }
// class UserService {
//     constructor(private logger: Logger) { }
//     getUser() {
//         this.logger.log('Obteniendo usuario');
//         return { name: 'Juan' };
//     }
// }
// const container = new DiContainer();
// container.register('Logger', Logger, []);
// container.register('UserService', UserService, ['Logger']);
// const userService = container.resolve<UserService>('UserService');
// userService.getUser();
