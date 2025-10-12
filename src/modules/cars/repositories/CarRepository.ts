import { CarWithId, CarDTO } from "../cars.types";

export interface CarRepository {
  create(data: CarDTO): Promise<CarWithId>;
  findById(id: number): Promise<CarWithId | null>;
  findAll(): Promise<CarWithId[]>;
  update(id: number, data: Partial<CarDTO>): Promise<CarWithId | null>;
  delete(id: number): Promise<boolean>;
}
