import { z } from "zod";
import { ScheduleController } from "./schedule.controller";
import GenericRouter from "@shared/classes/GenericRouter";
import { validate } from "@users/user.middleware";
import { validateParams } from "@shared/middlewares/zod/validateParams";
import { authenticate, requireRole } from "@auth/auth.middlewares";
import * as schema from "./schedule.schema";

export class ScheduleRouter extends GenericRouter {
  constructor(private readonly controller: ScheduleController) {
    super();
  }

  init() {
    const router = super.init();

    const idParamSchema = z.object({
      id: z.string().min(1, "ID requerido"),
    });

    const instructorIdParamSchema = z.object({
      instructorId: z.string().regex(/^\d+$/, "Instructor ID debe ser numérico").transform(Number),
    });

    const slotIdParamSchema = z.object({
      slotId: z.string().min(1, "Slot ID requerido"),
    });

    // Crear slot: solo INSTRUCTOR
    router.post("/slots",
      authenticate,
      requireRole("INSTRUCTOR"),
      validate(schema.createSlotSchema),
      this.controller.createSlot
    );

    router.get("/instructor/:instructorId", validateParams(instructorIdParamSchema), this.controller.getAvailableSlots);
    router.get("/preview/:slotId", authenticate, requireRole("STUDENT"), validateParams(slotIdParamSchema), this.controller.previewReservation);
    router.get("/:id", validateParams(idParamSchema), this.controller.getSlot);

    // Reservar slot: solo STUDENT
    router.post("/reserve/:slotId", authenticate, requireRole("STUDENT"), validateParams(slotIdParamSchema), this.controller.reserveSlot);

    // Cancelar hold/reserva: estudiante o instructor dueño
    router.post("/cancel/:slotId", authenticate, validateParams(slotIdParamSchema), this.controller.cancelReservation);

    // Eliminar slot: solo INSTRUCTOR
    router.delete("/:slotId", authenticate, requireRole("INSTRUCTOR"), validateParams(slotIdParamSchema), this.controller.deleteSlot);

    return router;
  }
}