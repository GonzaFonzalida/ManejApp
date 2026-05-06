import InstructorController from "./instructor.controller";
import GenericRouter from "@shared/classes/GenericRouter";
import { validate } from "@users/user.middleware";
import { validateParams } from "@shared/middlewares/zod/validateParams";
import { validateQuery } from "@shared/middlewares/zod/validateQuery";
import { authenticate, requireRole } from "@auth/auth.middlewares";
import * as schema from "./instructor.schema";
import { z } from "zod";
import express from "express";
import path from "path";

export default class InstructorRouter extends GenericRouter {
  constructor(private readonly controller: InstructorController) {
    super();
  }

  init() {
    const router = super.init();

    const idParamSchema = z.object({
      id: z.string().regex(/^\d+$/, "ID debe ser un número").transform(Number),
    });

    const instructorOnly = [authenticate, requireRole("INSTRUCTOR")];

    router.post("/register", validate(schema.createInstructorSchema), this.controller.register);

    router.get("/", this.controller.list);
    router.get("/nearby", validateQuery(schema.nearbyQuerySchema), this.controller.getNearby);

    router.get("/me", ...instructorOnly, this.controller.getMe);
    router.put("/me", ...instructorOnly, validate(schema.updateInstructorSchema), this.controller.updateMe);
    router.patch("/me/listed", ...instructorOnly, validate(schema.patchListedSchema), this.controller.patchListed);
    router.post("/me/documents", ...instructorOnly, validate(schema.uploadDocumentSchema), this.controller.uploadDocument);

    // Static route to serve documents (this could optionally have an auth check in the future)
    router.use("/documents", express.static(path.join(process.cwd(), "uploads", "instructors_docs")));

    router.get("/:id", validateParams(idParamSchema), this.controller.getPublicProfile);
    router.put("/:id", authenticate, validateParams(idParamSchema), validate(schema.updateInstructorSchema), this.controller.updateProfile);

    return router;
  }
}
