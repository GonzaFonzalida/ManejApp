import { Router } from "express";
import { z } from "zod";
import { ScheduleController } from "./schedule.controller";
import GenericRouter from "@shared/classes/GenericRouter";
import { validate } from "../../users/user.middleware";
import { validateParams } from "@shared/middlewares/zod/validateParams";
import * as schema from "./schedule.schema";

export class ScheduleRouter extends GenericRouter {
  constructor(private readonly controller: ScheduleController) {
    super();
  }

  init() {
    const router = super.init();

    // Esquema para validar parámetros ID
    const idParamSchema = z.object({
      id: z.string().min(1, "ID requerido"),
    });

    const instructorIdParamSchema = z.object({
      instructorId: z.string().regex(/^\d+$/, "Instructor ID debe ser numérico").transform(Number),
    });

    // Crear slot (INSTRUCTOR)
    router.post("/slots", validate(schema.createSlotSchema), this.controller.createSlot);

    // Obtener slot por ID
    router.get("/:id", validateParams(idParamSchema), this.controller.getSlot);

    // Listar slots disponibles de instructor
    router.get("/instructor/:instructorId", validateParams(instructorIdParamSchema), this.controller.getAvailableSlots);

    // Reservar slot (STUDENT)
    router.post("/reserve/:slotId", validateParams(idParamSchema), this.controller.reserveSlot);

    // Cancelar reserva
    router.post("/cancel/:slotId", validateParams(idParamSchema), this.controller.cancelReservation);

    // Eliminar slot (INSTRUCTOR)
    router.delete("/:slotId", validateParams(idParamSchema), this.controller.deleteSlot);

    return router;
  }
}