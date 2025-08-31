"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class CarService {
    cars;
    constructor(cars) {
        this.cars = cars;
    }
    async createCar(data) {
        return this.cars.create(data);
    }
    async getCarById(id) {
        return this.cars.findById(id);
    }
    async listCars() {
        return this.cars.findAll();
    }
    async updateCar(id, data) {
        return this.cars.update(id, data);
    }
    async deleteCar(id) {
        return this.cars.delete(id);
    }
}
exports.default = CarService;
