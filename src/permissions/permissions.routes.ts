import { Router } from "express";
import { PermissionController } from "./permissions.controller";
import { PermissionService } from "./permissions.services"
import { PrismaPermissionRepository } from "./repositories/PrismaPermissionsRepository";
import { validate } from "src/users/user.middleware";
import { createPermissionSchema, updatePermissionSchema } from "./permissions.schemas";

const permissionsRouter = Router();

const repository = new PrismaPermissionRepository();
const service = new PermissionService(repository);
const controller = new PermissionController(service);

permissionsRouter.post("/", validate(createPermissionSchema), controller.create);
permissionsRouter.get("/", controller.getAll);
permissionsRouter.get("/:id", controller.getById);
permissionsRouter.put("/:id", validate(updatePermissionSchema), controller.update); 
permissionsRouter.delete("/:id", controller.getById); // falta delete

export default permissionsRouter;
