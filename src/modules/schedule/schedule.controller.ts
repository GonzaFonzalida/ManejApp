import { Response } from "express";
import { ScheduleService } from "./schedule.service";
import { ExpressFunction } from "@shared/types/ExpressFunction";
import CustomizedError from "@shared/classes/CustomizedError";

export class ScheduleController {
  constructor(private scheduleService: ScheduleService) {}

  /**
   * @swagger
   * /schedule/slots:
   *   post:
   *     summary: Create a new schedule slot
   *     tags: [Schedule]
   *     security:
   *       - bearerAuth: []
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - instructorId
   *               - startTime
   *               - endTime
   *             properties:
   *               instructorId:
   *                 type: integer
   *                 minimum: 1
   *               startTime:
   *                 type: string
   *                 format: date-time
   *               endTime:
   *                 type: string
   *                 format: date-time
   *     responses:
   *       201:
   *         description: Slot created successfully
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  createSlot: ExpressFunction = async (req, res, next) => {
    try {
      const userId = req.user?.id;
      if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
      const instructor = await this.scheduleService.getInstructorIdByUserId(userId);
      if (!instructor) throw new CustomizedError("Instructor no encontrado", 403);
      const { startTime, endTime } = req.body;
      const slot = await this.scheduleService.createSlot(instructor.id, new Date(startTime), new Date(endTime));
      res.status(201).json(slot);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /schedule/{id}:
   *   get:
   *     summary: Get slot by ID
   *     tags: [Schedule]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: string
   *         description: Slot ID
   *     responses:
   *       200:
   *         description: Slot retrieved successfully
   *       404:
   *         description: Slot not found
   *       500:
   *         description: Internal server error
   */
  getSlot: ExpressFunction = async (req, res, next) => {
    try {
      const slot = await this.scheduleService.getSlotById(req.params.id);
      res.json(slot);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /schedule/instructor/{instructorId}:
   *   get:
   *     summary: Get available slots for instructor
   *     tags: [Schedule]
   *     parameters:
   *       - in: path
   *         name: instructorId
   *         required: true
   *         schema:
   *           type: integer
   *         description: Instructor ID
   *       - in: query
   *         name: startDate
   *         schema:
   *           type: string
   *           format: date-time
   *         description: Start date filter
   *       - in: query
   *         name: endDate
   *         schema:
   *           type: string
   *           format: date-time
   *         description: End date filter
   *     responses:
   *       200:
   *         description: Available slots retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: array
   *               items:
   *                 type: object
   *       500:
   *         description: Internal server error
   */
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

  previewReservation: ExpressFunction = async (req, res, next) => {
    try {
      const { slotId } = req.params;
      const userId = req.user?.id;
      if (!userId) throw new CustomizedError("Usuario no autenticado", 401);

      const result = await this.scheduleService.getReservationPreview(slotId, userId);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /schedule/reserve/{slotId}:
   *   post:
   *     summary: Reserve a slot
   *     tags: [Schedule]
   *     security:
   *       - bearerAuth: []
   *     parameters:
   *       - in: path
   *         name: slotId
   *         required: true
   *         schema:
   *           type: string
   *         description: Slot ID to reserve
   *     responses:
   *       201:
   *         description: Slot reserved successfully
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  reserveSlot: ExpressFunction = async (req, res, next) => {
    try {
      const { slotId } = req.params;
      const userId = req.user?.id;
      if (!userId) throw new CustomizedError("Usuario no autenticado", 401);

      const result = await this.scheduleService.reserveSlot(slotId, userId);
      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /schedule/cancel/{slotId}:
   *   post:
   *     summary: Cancel reservation
   *     tags: [Schedule]
   *     security:
   *       - bearerAuth: []
   *     parameters:
   *       - in: path
   *         name: slotId
   *         required: true
   *         schema:
   *           type: string
   *         description: Slot ID to cancel reservation
   *     responses:
   *       200:
   *         description: Reservation canceled successfully
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  cancelReservation: ExpressFunction = async (req, res, next) => {
    try {
      const { slotId } = req.params;
      const userId = req.user?.id;
      const userRole = req.user?.role;
      if (!userId || !userRole) throw new CustomizedError("Usuario no autenticado", 401);

      const result = await this.scheduleService.cancelReservation(slotId, userId, userRole);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /schedule/{slotId}:
   *   delete:
   *     summary: Delete slot
   *     tags: [Schedule]
   *     security:
   *       - bearerAuth: []
   *     parameters:
   *       - in: path
   *         name: slotId
   *         required: true
   *         schema:
   *           type: string
   *         description: Slot ID to delete
   *     responses:
   *       204:
   *         description: Slot deleted successfully
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  deleteSlot: ExpressFunction = async (req, res, next) => {
    try {
      const { slotId } = req.params;
      const userId = req.user?.id;
      if (!userId) throw new CustomizedError("Usuario no autenticado", 401);

      await this.scheduleService.deleteSlot(slotId, userId);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  };
}