import { Router } from "express";
import CarController from "./cars.controller";
import CarService from "./cars.services";
import { PrismaCarRepository } from "./repositories/PrismaCarRepository";
import { validate } from "@shared/middlewares/zod/validateBody";
import { carSchema, updateCarSchema } from "./cars.schemas";

const repo = new PrismaCarRepository();
const service = new CarService(repo);
const controller = new CarController(service);

const carRouters = Router();

carRouters.post("/", validate(carSchema), controller.create.bind(controller));
carRouters.get("/", controller.list.bind(controller));
carRouters.get("/:id", controller.getById.bind(controller));
carRouters.put("/:id", validate(updateCarSchema), controller.update.bind(controller));
carRouters.delete("/:id", controller.delete.bind(controller));

export default carRouters;
