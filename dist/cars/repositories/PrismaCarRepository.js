"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PrismaCarRepository = void 0;
const prismaClient_1 = require("../../config/prismaClient");
class PrismaCarRepository {
    async create(data) {
        const car = await prismaClient_1.prisma.car.create({ data });
        return car;
    }
    async findById(id) {
        return prismaClient_1.prisma.car.findUnique({ where: { id } });
    }
    async findAll() {
        return prismaClient_1.prisma.car.findMany();
    }
    async update(id, data) {
        try {
            return await prismaClient_1.prisma.car.update({ where: { id }, data });
        }
        catch {
            return null;
        }
    }
    async delete(id) {
        try {
            await prismaClient_1.prisma.car.delete({ where: { id } });
            return true;
        }
        catch {
            return false;
        }
    }
}
exports.PrismaCarRepository = PrismaCarRepository;
