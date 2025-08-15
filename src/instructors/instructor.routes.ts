import { Router } from "express";
import InstructorController  from "./instructor.controller";
import diContainer from "../DiContainer/container";
import GenericRouter from "@shared/classes/GenericRouter";
import { validate } from "src/users/user.middleware";
import * as schema from "./instructor.schema"


export default class InstructorRouter extends GenericRouter {
    constructor(private readonly controller: InstructorController) {

        super();
        const router = this.init();
        router.post("/register", validate(schema.createInstructorSchema), controller.register);
        router.get("/:id", controller.getProfile);
        router.get("/", controller.list);
        router.put("/:id", validate(schema.updateInstructorSchema), controller.updateProfile);
    }
}

