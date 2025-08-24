// src/permissions/repositories/prismaPermissionRepository.ts
import { PrismaClient } from "@prisma/client";
import { PermissionRepository } from "./IPermissionsRepository";
import { Permission } from "../entities/Permission";
import CustomizedError from "@shared/classes/CustomizedError";

const prisma = new PrismaClient();

export class PrismaPermissionRepository implements PermissionRepository {
  async create(data: Omit<Permission, "id">): Promise<Permission> {
    const created = await prisma.permission.create({ data });
    if (!created.description){
      created.description = "";
    }
    return new Permission(created.id, created.name, created.description, created.isMandatory);
  }

  async findById(id: number): Promise<Permission | null> {
    const found = await prisma.permission.findUnique({ where: { id } });
    
    return found ? new Permission(found.id, found.name, found.description ?? "", found.isMandatory) : null;
  }

  async findAll(): Promise<Permission[]> {
    const permissions = await prisma.permission.findMany();
    return permissions.map(
      (p) => new Permission(p.id, p.name, p.description ?? "", p.isMandatory)
    );
  }

  async update(id: number, data: Partial<Permission>): Promise<Permission | null> {
    try {
      const updated = await prisma.permission.update({ where: { id }, data });
      return new Permission(updated.id, updated.name, updated.description ?? "", updated.isMandatory);
    } catch {
      return null;
    }
  }

  async delete(id: number): Promise<boolean> {
    try {
      await prisma.permission.delete({ where: { id } });
      return true;
    } catch {
      return false;
    }
  }
}
