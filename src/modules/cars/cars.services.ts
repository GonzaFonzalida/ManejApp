import { CarRepository } from "./repositories/CarRepository";
import { CarDTO, CarWithId } from "./cars.types";

export default class CarService {
  constructor(private readonly cars: CarRepository) {}

  async createCar(data: CarDTO): Promise<CarWithId> {
    return this.cars.create(data);
  }

  async getCarById(id: number): Promise<CarWithId | null> {
    return this.cars.findById(id);
  }

  async listCars(): Promise<CarWithId[]> {
    return this.cars.findAll();
  }

  async updateCar(id: number, data: Partial<CarDTO>): Promise<CarWithId | null> {
    return this.cars.update(id, data);
  }

  async deleteCar(id: number): Promise<boolean> {
    return this.cars.delete(id);
  }
}
