import { Permission } from "../entities/Permission";

export interface PermissionRepository {
  create(data: Omit<Permission, "id">): Promise<Permission>;
  findById(id: number): Promise<Permission | null>;
  findAll(): Promise<Permission[]>;
  update(id: number, data: Partial<Permission>): Promise<Permission | null>;
  delete(id: number): Promise<boolean>;
}
