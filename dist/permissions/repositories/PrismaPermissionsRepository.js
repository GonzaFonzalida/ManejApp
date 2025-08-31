"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PrismaPermissionRepository = void 0;
// src/permissions/repositories/prismaPermissionRepository.ts
const client_1 = require("@prisma/client");
const Permission_1 = require("../entities/Permission");
const prisma = new client_1.PrismaClient();
class PrismaPermissionRepository {
    async create(data) {
        const created = await prisma.permission.create({ data });
        if (!created.description) {
            created.description = "";
        }
        return new Permission_1.Permission(created.id, created.name, created.description, created.isMandatory);
    }
    async findById(id) {
        const found = await prisma.permission.findUnique({ where: { id } });
        return found ? new Permission_1.Permission(found.id, found.name, found.description ?? "", found.isMandatory) : null;
    }
    async findAll() {
        const permissions = await prisma.permission.findMany();
        return permissions.map((p) => new Permission_1.Permission(p.id, p.name, p.description ?? "", p.isMandatory));
    }
    async update(id, data) {
        try {
            const updated = await prisma.permission.update({ where: { id }, data });
            return new Permission_1.Permission(updated.id, updated.name, updated.description ?? "", updated.isMandatory);
        }
        catch {
            return null;
        }
    }
    async delete(id) {
        try {
            await prisma.permission.delete({ where: { id } });
            return true;
        }
        catch {
            return false;
        }
    }
}
exports.PrismaPermissionRepository = PrismaPermissionRepository;
