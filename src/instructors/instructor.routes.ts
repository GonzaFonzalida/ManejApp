import { Router } from "express";
import InstructorController  from "./instructor.controller";
import diContainer from "../DiContainer/container";
import GenericRouter from "@shared/classes/GenericRouter";

// router.post("/", controller.register);
// router.get("/:id", controller.getProfile);
// router.get("/", controller.list);
export default class InstructorRouter extends GenericRouter {
    constructor(private readonly controller: InstructorController) {

        super();
        const router = this.init();
        router.post("/", controller.register);
        router.get("/:id", controller.getProfile);
        router.get("/", controller.list);
    }
}

