import { z } from "zod";
import { DrivingClassController } from "./controller";
import GenericRouter from "@shared/classes/GenericRouter";
import { createDrivingClassSchema, updateDrivingClassSchema } from "./schemas";
import { validate } from "@shared/middlewares/zod/validateBody";
import { validateParams } from "@shared/middlewares/zod/validateParams";

import { authenticate } from "@auth/auth.middlewares";

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

    router.get("/", authenticate, this.drivingClassController.list);
    router.get("/my-classes", authenticate, this.drivingClassController.myClasses);
    router.get("/upcoming", authenticate, this.drivingClassController.upcoming);
    router.get("/history", authenticate, this.drivingClassController.history);
    router.get("/student/upcoming", authenticate, this.drivingClassController.studentUpcomingPremium);
    router.get("/student/history", authenticate, this.drivingClassController.studentHistoryPremium);
    router.get("/student/:id", authenticate, validateParams(idParamSchema), this.drivingClassController.studentDetailPremium);
    router.get("/instructor/upcoming", authenticate, this.drivingClassController.instructorUpcomingPremium);
    router.get("/instructor/history", authenticate, this.drivingClassController.instructorHistoryPremium);
    router.get("/instructor/:id", authenticate, validateParams(idParamSchema), this.drivingClassController.instructorDetailPremium);
    router.get("/:id", authenticate, validateParams(idParamSchema), this.drivingClassController.getById);

    router.post("/", authenticate, validate(createDrivingClassSchema), this.drivingClassController.create);
    router.put("/:id", authenticate, validateParams(idParamSchema), validate(updateDrivingClassSchema), this.drivingClassController.update);

    router.patch("/:id/cancel", authenticate, validateParams(idParamSchema), this.drivingClassController.cancel);

    router.delete("/:id", authenticate, validateParams(idParamSchema), this.drivingClassController.delete);

    return router;
  }
}

