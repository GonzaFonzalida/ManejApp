import { Response } from "express";
import { ScheduleService } from "./schedule.service";
import { ExpressFunction } from "@shared/types/ExpressFunction";
import CustomizedError from "@shared/classes/CustomizedError";

export class ScheduleController {
  constructor(private scheduleService: ScheduleService) {}

  createSlot: ExpressFunction = async (req, res, next) => {
    try {
      const { instructorId, startTime, endTime } = req.body;
      const slot = await this.scheduleService.createSlot(instructorId, new Date(startTime), new Date(endTime));
      res.status(201).json(slot);
    } catch (err) {
      next(err);
    }
  };

  getSlot: ExpressFunction = async (req, res, next) => {
    try {
      const slot = await this.scheduleService.getSlotById(req.params.id);
      res.json(slot);
    } catch (err) {
      next(err);
    }
  };

  getAvailableSlots: ExpressFunction = async (req, res, next) => {
    try {
      const { instructorId } = req.params;
      const { startDate, endDate } = req.query;
      const slots = await this.scheduleService.getAvailableSlots(
        Number(instructorId),
        startDate ? new Date(startDate as string) : undefined,
        endDate ? new Date(endDate as string) : undefined
      );
      res.json(slots);
    } catch (err) {
      next(err);
    }
  };

  reserveSlot: ExpressFunction = async (req, res, next) => {
    try {
      const { slotId } = req.params;
      const studentId = req.user?.id;
      if (!studentId) throw new CustomizedError("Usuario no autenticado", 401);

      const result = await this.scheduleService.reserveSlot(slotId, studentId);
      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  };

  cancelReservation: ExpressFunction = async (req, res, next) => {
    try {
      const { slotId } = req.params;
      const userId = req.user?.id;
      const userRole = req.user?.role;
      if (!userId || !userRole) throw new CustomizedError("Usuario no autenticado", 401);

      const slot = await this.scheduleService.cancelReservation(slotId, userId, userRole);
      res.json(slot);
    } catch (err) {
      next(err);
    }
  };

  deleteSlot: ExpressFunction = async (req, res, next) => {
    try {
      const { slotId } = req.params;
      const instructorId = req.user?.id;
      if (!instructorId) throw new CustomizedError("Usuario no autenticado", 401);

      await this.scheduleService.deleteSlot(slotId, instructorId);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  };
}