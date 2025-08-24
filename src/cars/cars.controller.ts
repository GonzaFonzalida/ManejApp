import { Request, Response } from "express";
import CarService from "./cars.services";
import CustomizedError from "../shared/classes/CustomizedError";

export default class CarController {
  constructor(private readonly service: CarService) {}

  async create(req: Request, res: Response) {
    try {
      const car = await this.service.createCar(req.body);
      return res.status(201).json(car);
    } catch (e) {
      throw new CustomizedError("Error al registrar el auto", 500);
    }
  }

  async getById(req: Request, res: Response) {
    const car = await this.service.getCarById(Number(req.params.id));
    if (!car) throw new CustomizedError("Auto no encontrado", 404);
    return res.json(car);
  }

  async list(req: Request, res: Response) {
    const cars = await this.service.listCars();
    return res.json(cars);
  }

  async update(req: Request, res: Response) {
    const car = await this.service.updateCar(Number(req.params.id), req.body);
    if (!car) throw new CustomizedError("No se pudo actualizar el auto", 400);
    return res.json(car);
  }

  async delete(req: Request, res: Response) {
    const ok = await this.service.deleteCar(Number(req.params.id));
    if (!ok) throw new CustomizedError("No se pudo eliminar el auto", 400);
    return res.json({ ok: true });
  }
}
