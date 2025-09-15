import { z } from "zod";
import { DrivingClassController } from "./controller";
import GenericRouter from "../shared/classes/GenericRouter";
import {createDrivingClassSchema, updateDrivingClassSchema} from "./schemas";
import { validate } from "@shared/middlewares/zod/validateBody";
import { validateParams } from "@shared/middlewares/zod/validateParams";

export default class DrivingClassRouter extends GenericRouter {
  constructor(private readonly drivingClassController: DrivingClassController) {
    super();
  }

  init() {
    const router = super.init();

    // Esquema para validar parámetros ID
    const idParamSchema = z.object({
      id: z.string().regex(/^\d+$/, "ID debe ser un número").transform(Number)
    });

    router.get("/", this.drivingClassController.list);
    router.get("/:id", validateParams(idParamSchema), this.drivingClassController.getById);

    router.post("/", validate(createDrivingClassSchema), this.drivingClassController.create);
    router.put("/:id", validateParams(idParamSchema), validate(updateDrivingClassSchema), this.drivingClassController.update);

    router.patch("/:id/cancel", validateParams(idParamSchema), this.drivingClassController.cancel);

    router.delete("/:id", validateParams(idParamSchema), this.drivingClassController.delete);

    return router;
  }
}

