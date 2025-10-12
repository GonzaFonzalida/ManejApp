import { DrivingClass } from "../entities/DrivingClass";

export interface DrivingClassRepository {
  create(data: Omit<DrivingClass, "id">): Promise<DrivingClass>;
  findById(id: number): Promise<DrivingClass | null>;
  findAll(): Promise<DrivingClass[]>;
  update(id: number, data: Partial<DrivingClass>): Promise<DrivingClass>;
  delete(id: number): Promise<void>;
}
