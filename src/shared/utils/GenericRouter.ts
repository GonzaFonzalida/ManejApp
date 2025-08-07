import { Router, RequestHandler } from "express";

export abstract class GenericRouter {
    protected router: Router;

    
    constructor(middlewares: RequestHandler[] = []) {
        this.router = Router();
        if (middlewares.length) {
            this.router.use(...middlewares);
        }
        this.initRoutes();
    }
    
    protected abstract initRoutes(): void;

    public getRouter(): Router {
        return this.router;
    }
}
