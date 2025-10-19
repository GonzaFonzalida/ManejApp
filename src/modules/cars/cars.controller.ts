import { Request, Response } from "express";
import CarService from "./cars.services";
import CustomizedError from "@classes/CustomizedError";

export default class CarController {
  constructor(private readonly service: CarService) {}

  /**
   * @swagger
   * /cars:
   *   post:
   *     summary: Create a new car
   *     tags: [Cars]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - brand
   *               - model
   *               - instructorId
   *               - year
   *               - licensePlate
   *               - transmission
   *             properties:
   *               brand:
   *                 type: string
   *                 minLength: 2
   *               model:
   *                 type: string
   *                 minLength: 1
   *               instructorId:
   *                 type: integer
   *               year:
   *                 type: integer
   *                 minimum: 1990
   *               licensePlate:
   *                 type: string
   *                 minLength: 5
   *               transmission:
   *                 type: string
   *                 enum: [MANUAL, AUTOMATIC]
   *     responses:
   *       201:
   *         description: Car created successfully
   *       500:
   *         description: Internal server error
   */
  async create(req: Request, res: Response) {
    try {
      const car = await this.service.createCar(req.body);
      return res.status(201).json(car);
    } catch (e) {
      throw new CustomizedError("Error al registrar el auto", 500);
    }
  }

  /**
   * @swagger
   * /cars/{id}:
   *   get:
   *     summary: Get car by ID
   *     tags: [Cars]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Car ID
   *     responses:
   *       200:
   *         description: Car retrieved successfully
   *       404:
   *         description: Car not found
   *       500:
   *         description: Internal server error
   */
  async getById(req: Request, res: Response) {
    const car = await this.service.getCarById(Number(req.params.id));
    if (!car) throw new CustomizedError("Auto no encontrado", 404);
    return res.json(car);
  }

  /**
   * @swagger
   * /cars:
   *   get:
   *     summary: Get all cars
   *     tags: [Cars]
   *     responses:
   *       200:
   *         description: Cars retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: array
   *               items:
   *                 type: object
   *       500:
   *         description: Internal server error
   */
  async list(req: Request, res: Response) {
    const cars = await this.service.listCars();
    return res.json(cars);
  }

  /**
   * @swagger
   * /cars/{id}:
   *   put:
   *     summary: Update car by ID
   *     tags: [Cars]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Car ID
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             properties:
   *               brand:
   *                 type: string
   *               model:
   *                 type: string
   *               instructorId:
   *                 type: integer
   *               year:
   *                 type: integer
   *               licensePlate:
   *                 type: string
   *               transmission:
   *                 type: string
   *                 enum: [MANUAL, AUTOMATIC]
   *     responses:
   *       200:
   *         description: Car updated successfully
   *       400:
   *         description: Bad request
   *       500:
   *         description: Internal server error
   */
  async update(req: Request, res: Response) {
    const car = await this.service.updateCar(Number(req.params.id), req.body);
    if (!car) throw new CustomizedError("No se pudo actualizar el auto", 400);
    return res.json(car);
  }

  /**
   * @swagger
   * /cars/{id}:
   *   delete:
   *     summary: Delete car by ID
   *     tags: [Cars]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Car ID
   *     responses:
   *       200:
   *         description: Car deleted successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 ok:
   *                   type: boolean
   *       400:
   *         description: Bad request
   *       500:
   *         description: Internal server error
   */
  async delete(req: Request, res: Response) {
    const ok = await this.service.deleteCar(Number(req.params.id));
    if (!ok) throw new CustomizedError("No se pudo eliminar el auto", 400);
    return res.json({ ok: true });
  }
}
