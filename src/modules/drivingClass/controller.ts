import { DrivingClassService } from "./services";
import { ExpressFunction } from "@shared/types/ExpressFunction";
import CustomizedError from "@shared/classes/CustomizedError";
import { Role } from "@prisma/client";

function parseRoleOrThrow(rawRole: string | undefined): Role {
  if (!rawRole) throw new CustomizedError("Usuario no autenticado", 401);
  const allowed: Role[] = ["ADMIN", "STUDENT", "INSTRUCTOR"];
  if (!allowed.includes(rawRole as Role)) {
    throw new CustomizedError("Rol inválido", 403);
  }
  return rawRole as Role;
}
export class DrivingClassController {
  constructor(private service: DrivingClassService) {}

/**
 * @swagger
 * /classes:
 *   post:
 *     summary: Create a new driving class
 *     tags: [Driving Classes]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - instructorId
 *               - studentId
 *               - date
 *               - duration
 *               - status
 *             properties:
 *               instructorId:
 *                 type: integer
 *                 minimum: 1
 *               studentId:
 *                 type: integer
 *                 minimum: 1
 *               date:
 *                 type: string
 *                 format: date-time
 *               duration:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 180
 *               status:
 *                 type: string
 *                 enum: [scheduled, completed, canceled]
 *     responses:
 *       201:
 *         description: Driving class created successfully
 *       500:
 *         description: Internal server error
 */
create : ExpressFunction = async(req, res) => {
    const drivingClass = await this.service.create(req.body);
    res.status(201).json(drivingClass);
  }

/**
 * @swagger
 * /classes:
 *   get:
 *     summary: Get all driving classes
 *     tags: [Driving Classes]
 *     responses:
 *       200:
 *         description: Driving classes retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *       500:
 *         description: Internal server error
 */
list : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    const classes = await this.service.listClassesByRole(userId, role, "all");
    res.json(classes);
  }

myClasses : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);

    const rawScope = String(req.query.scope ?? "all").toLowerCase();
    const scope = rawScope === "upcoming" || rawScope === "history" ? rawScope : "all";
    const classes = await this.service.listClassesByRole(userId, role, scope);
    res.json(classes);
  }

upcoming : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    const classes = await this.service.listClassesByRole(userId, role, "upcoming");
    res.json(classes);
  }

history : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    const classes = await this.service.listClassesByRole(userId, role, "history");
    res.json(classes);
  }

studentUpcomingPremium : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    if (role !== "STUDENT") throw new CustomizedError("Solo estudiantes", 403);
    const reservations = await this.service.listStudentReservationsPremium(userId, "upcoming");
    res.json(reservations);
  }

studentHistoryPremium : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    if (role !== "STUDENT") throw new CustomizedError("Solo estudiantes", 403);
    const reservations = await this.service.listStudentReservationsPremium(userId, "history");
    res.json(reservations);
  }

studentDetailPremium : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    if (role !== "STUDENT") throw new CustomizedError("Solo estudiantes", 403);
    const reservation = await this.service.getStudentReservationDetailPremium(Number(req.params.id), userId);
    if (!reservation) return res.status(404).json({ message: "Class not found" });
    res.json(reservation);
  }

instructorUpcomingPremium : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    if (role !== "INSTRUCTOR") throw new CustomizedError("Solo instructores", 403);
    const reservations = await this.service.listInstructorReservationsPremium(userId, "upcoming");
    res.json(reservations);
  }

instructorHistoryPremium : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    if (role !== "INSTRUCTOR") throw new CustomizedError("Solo instructores", 403);
    const reservations = await this.service.listInstructorReservationsPremium(userId, "history");
    res.json(reservations);
  }

instructorDetailPremium : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    if (role !== "INSTRUCTOR") throw new CustomizedError("Solo instructores", 403);
    const reservation = await this.service.getInstructorReservationDetailPremium(Number(req.params.id), userId);
    if (!reservation) return res.status(404).json({ message: "Class not found" });
    res.json(reservation);
  }

/**
 * @swagger
 * /classes/{id}:
 *   get:
 *     summary: Get driving class by ID
 *     tags: [Driving Classes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Driving class ID
 *     responses:
 *       200:
 *         description: Driving class retrieved successfully
 *       404:
 *         description: Driving class not found
 *       500:
 *         description: Internal server error
 */
getById : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    const cls = await this.service.getClassByIdForUser(Number(req.params.id), userId, role);
    if (!cls) return res.status(404).json({ message: "Class not found" });
    res.json(cls);
  }

/**
 * @swagger
 * /classes/{id}:
 *   put:
 *     summary: Update driving class by ID
 *     tags: [Driving Classes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Driving class ID
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               date:
 *                 type: string
 *                 format: date-time
 *               duration:
 *                 type: integer
 *                 minimum: 1
 *                 maximum: 180
 *               status:
 *                 type: string
 *                 enum: [scheduled, completed, canceled]
 *     responses:
 *       200:
 *         description: Driving class updated successfully
 *       500:
 *         description: Internal server error
 */
update : ExpressFunction = async(req, res) => {
    const cls = await this.service.updateClass(Number(req.params.id), req.body);
    res.json(cls);
  }

/**
 * @swagger
 * /classes/{id}/cancel:
 *   patch:
 *     summary: Cancel driving class by ID
 *     tags: [Driving Classes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Driving class ID
 *     responses:
 *       204:
 *         description: Driving class canceled successfully
 *       500:
 *         description: Internal server error
 */
cancel : ExpressFunction = async(req, res) => {
    const userId = req.user?.id;
    const role = parseRoleOrThrow(req.user?.role);
    if (!userId) throw new CustomizedError("Usuario no autenticado", 401);
    const result = await this.service.cancelClassForUser(Number(req.params.id), userId, role);
    res.status(200).json({
      success: true,
      alreadyCancelled: result.alreadyCancelled,
    });
  }

/**
 * @swagger
 * /classes/{id}:
 *   delete:
 *     summary: Delete driving class by ID
 *     tags: [Driving Classes]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *         description: Driving class ID
 *     responses:
 *       204:
 *         description: Driving class deleted successfully
 *       500:
 *         description: Internal server error
 */
delete : ExpressFunction = async(req, res) => {
    await this.service.deleteClass(Number(req.params.id));
    res.status(204).send();
  }
}
