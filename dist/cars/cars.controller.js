"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const CustomizedError_1 = __importDefault(require("../shared/classes/CustomizedError"));
class CarController {
    service;
    constructor(service) {
        this.service = service;
    }
    async create(req, res) {
        try {
            const car = await this.service.createCar(req.body);
            return res.status(201).json(car);
        }
        catch (e) {
            throw new CustomizedError_1.default("Error al registrar el auto", 500);
        }
    }
    async getById(req, res) {
        const car = await this.service.getCarById(Number(req.params.id));
        if (!car)
            throw new CustomizedError_1.default("Auto no encontrado", 404);
        return res.json(car);
    }
    async list(req, res) {
        const cars = await this.service.listCars();
        return res.json(cars);
    }
    async update(req, res) {
        const car = await this.service.updateCar(Number(req.params.id), req.body);
        if (!car)
            throw new CustomizedError_1.default("No se pudo actualizar el auto", 400);
        return res.json(car);
    }
    async delete(req, res) {
        const ok = await this.service.deleteCar(Number(req.params.id));
        if (!ok)
            throw new CustomizedError_1.default("No se pudo eliminar el auto", 400);
        return res.json({ ok: true });
    }
}
exports.default = CarController;
