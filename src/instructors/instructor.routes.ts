import { Router } from "express";
import { z } from "zod";
import InstructorController  from "./instructor.controller";
import diContainer from "../DiContainer/container";
import GenericRouter from "@shared/classes/GenericRouter";
import { validate } from "../users/user.middleware";
import { validateParams } from "@shared/middlewares/zod/validateParams";
import * as schema from "./instructor.schema";


export default class InstructorRouter extends GenericRouter {
    constructor(private readonly controller: InstructorController) {
        super();
    }

    init() {
        const router = super.init();
        
        // Esquema para validar parámetros ID
        const idParamSchema = z.object({
            id: z.string().regex(/^\d+$/, "ID debe ser un número").transform(Number)
        });

        router.post("/register", validate(schema.createInstructorSchema), this.controller.register);
        router.get("/:id", validateParams(idParamSchema), this.controller.getProfile);
        router.get("/", this.controller.list);
        router.put("/:id", validateParams(idParamSchema), validate(schema.updateInstructorSchema), this.controller.updateProfile);

        return router;
    }
}

