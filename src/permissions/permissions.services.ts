// src/permissions/services/permission.service.ts
import { PermissionRepository } from "./repositories/IPermissionsRepository";
import { Permission } from "./entities/Permission";

export class PermissionService {
  constructor(private repository: PermissionRepository) {}

  async createPermission(data: Omit<Permission, "id">): Promise<Permission> {
    return this.repository.create(data);
  }

  async getPermission(id: number): Promise<Permission | null> {
    return this.repository.findById(id);
  }

  async getAllPermissions(): Promise<Permission[]> {
    return this.repository.findAll();
  }

  async updatePermission(id: number, data: Partial<Permission>): Promise<Permission | null> {
    return this.repository.update(id, data);
  }

  async deletePermission(id: number): Promise<boolean> {
    return this.repository.delete(id);
  }
}
