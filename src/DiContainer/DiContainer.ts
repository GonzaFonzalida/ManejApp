interface InjectableService<T> {
    implementation: new (...args: any[]) => T;
    dependencies: string[];
    singlenton: boolean;
}

type SinglentonIntance = any;

export default class DiContainer {
    private services: Map<string, InjectableService<any>>;
    private singletons: Map<string, SinglentonIntance>;

    constructor() {
        this.services = new Map();
        this.singletons = new Map();
    }

    register<T>(
        name: string,
        implementation: new (...args: any[]) => T,
        dependencies: string[] = [],
    ) {
        this.services.set(name, {
            implementation,
            dependencies,
            singlenton: false
        }
        )
    }

    registerSinglenton<T>(
        name: string,
        implementation: new (...args: any[]) => T,
        dependencies: string[],
    ) {
        this.services.set(name, {
            implementation,
            dependencies,
            singlenton: true
        }
        )
    }
    registeIntance<T>(name: string, instance: T) {
        this.singletons.set(name, instance);
    }
    resolve<T>(name: string): T {
        if (this.singletons.has(name)) {
            return this.singletons.get(name);
        }

        const services = this.services.get(name);

        if (!services) {
            throw new Error(`el servicio es requerido ${name}`)
        }

        const dependencies = services.dependencies.map((dep) => this.resolve(dep));
        const instance = new services.implementation(...dependencies);


        if (services.singlenton && !this.services.has(name)) {
            this.singletons.set(name, instance)
        }

        return instance;
    }

}


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