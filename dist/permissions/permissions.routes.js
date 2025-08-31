"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const permissions_controller_1 = require("./permissions.controller");
const permissions_services_1 = require("./permissions.services");
const PrismaPermissionsRepository_1 = require("./repositories/PrismaPermissionsRepository");
const user_middleware_1 = require("src/users/user.middleware");
const permissions_schemas_1 = require("./permissions.schemas");
const permissionsRouter = (0, express_1.Router)();
const repository = new PrismaPermissionsRepository_1.PrismaPermissionRepository();
const service = new permissions_services_1.PermissionService(repository);
const controller = new permissions_controller_1.PermissionController(service);
permissionsRouter.post("/", (0, user_middleware_1.validate)(permissions_schemas_1.createPermissionSchema), controller.create);
permissionsRouter.get("/", controller.getAll);
permissionsRouter.get("/:id", controller.getById);
permissionsRouter.put("/:id", (0, user_middleware_1.validate)(permissions_schemas_1.updatePermissionSchema), controller.update);
permissionsRouter.delete("/:id", controller.getById); // falta delete
exports.default = permissionsRouter;
