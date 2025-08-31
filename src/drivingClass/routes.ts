import { DrivingClassController } from "./controller";
import GenericRouter from "../shared/classes/GenericRouter";
import {createDrivingClassSchema, updateDrivingClassSchema} from "./schemas"
import { validate } from "@shared/middlewares/zod/validateBody";

export default class DrivingClassRouter extends GenericRouter {
  constructor(private readonly drivingClassController: DrivingClassController) {
    super();
    const router = this.init();

    router.get("/", this.drivingClassController.list);
    router.get("/:id", this.drivingClassController.getById);

    router.post("/", validate(createDrivingClassSchema), this.drivingClassController.create);
    router.put("/:id", validate(updateDrivingClassSchema), this.drivingClassController.update);

    router.patch("/:id/cancel", this.drivingClassController.cancel);

    router.delete("/:id", this.drivingClassController.delete);
  }
}

