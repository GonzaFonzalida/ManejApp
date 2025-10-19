import { Request, Response } from "express";
import  InstructorService from "./instructor.services";
import { ExpressFunction } from "@sharedTypes/ExpressFunction";
import CustomizedError from "@shared/classes/CustomizedError";

export default class InstructorController {
  constructor(private instructorService: InstructorService) {}

  /**
   * @swagger
   * /instructors/register:
   *   post:
   *     summary: Register a new instructor
   *     tags: [Instructors]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - userId
   *               - licenseNumber
   *               - experienceYears
   *             properties:
   *               userId:
   *                 type: integer
   *                 minimum: 1
   *               licenseNumber:
   *                 type: string
   *                 minLength: 5
   *                 maxLength: 20
   *               experienceYears:
   *                 type: integer
   *                 minimum: 0
   *                 maximum: 50
   *               carId:
   *                 type: integer
   *                 minimum: 1
   *     responses:
   *       201:
   *         description: Instructor registered successfully
   *       500:
   *         description: Internal server error
   */
  register: ExpressFunction = async (req, res, next)=> {
    try {
      const instructor = await this.instructorService.registerInstructor(req.body);
      res.status(201).json(instructor);
    } catch (err) {
      next(err);
    }
  };
  /**
   * @swagger
   * /instructors/{id}:
   *   put:
   *     summary: Update instructor profile by ID
   *     tags: [Instructors]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Instructor ID
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             properties:
   *               licenseNumber:
   *                 type: string
   *                 minLength: 5
   *                 maxLength: 20
   *               experienceYears:
   *                 type: integer
   *                 minimum: 0
   *                 maximum: 50
   *               available:
   *                 type: boolean
   *               isValid:
   *                 type: boolean
   *               carId:
   *                 type: integer
   *                 minimum: 1
   *     responses:
   *       200:
   *         description: Instructor updated successfully
   *       404:
   *         description: Instructor not found
   *       500:
   *         description: Internal server error
   */
  updateProfile: ExpressFunction = async (req, res, next) => {
    try {
      const instructorId = Number(req.params.id);

      const updatedInstructor = await this.instructorService.updateInstructor(
        instructorId,
        req.body
      );

      if (!updatedInstructor) {
        return next(new CustomizedError("Instructor no encontrado", 404));
      }

      return res.json(updatedInstructor);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /instructors/{id}:
   *   get:
   *     summary: Get instructor profile by ID
   *     tags: [Instructors]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Instructor ID
   *     responses:
   *       200:
   *         description: Instructor profile retrieved successfully
   *       404:
   *         description: Instructor not found
   *       500:
   *         description: Internal server error
   */
  getProfile: ExpressFunction = async (req, res, next) => {
    try {
      const instructor = await this.instructorService.getInstructorProfile(Number(req.params.id));
      if (!instructor) {
        return next(new CustomizedError("Instructor no encontrado, ingrese un perfil válido", 404));
      }
      res.json(instructor);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /instructors:
   *   get:
   *     summary: Get all instructors
   *     tags: [Instructors]
   *     responses:
   *       200:
   *         description: Instructors retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: array
   *               items:
   *                 type: object
   *       500:
   *         description: Internal server error
   */
  list: ExpressFunction = async (req, res, next) => {
    try {
      const instructors = await this.instructorService.listInstructors();
      res.json(instructors);
    } catch (err) {
      next(err);
    }
  };
}
