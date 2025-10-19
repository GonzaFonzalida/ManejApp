import { CarWithId, CarDTO } from "../cars.types";

export interface CarRepository {
  create(data: CarDTO): Promise<CarWithId>;
  findById(id: number): Promise<CarWithId | null>;
  findAll(): Promise<CarWithId[]>;
  findMany(page: number, limit: number, filters: any): Promise<CarWithId[]>;
  count(filters: any): Promise<number>;
  update(id: number, data: Partial<CarDTO>): Promise<CarWithId | null>;
  delete(id: number): Promise<boolean>;
}
