"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PrismaDrivingClassRepository = void 0;
const prismaClient_1 = require("../../config/prismaClient");
class PrismaDrivingClassRepository {
    prisma = prismaClient_1.prisma;
    constructor() { }
    async create(data) {
        return this.prisma.drivingClass.create({
            data: {
                ...data,
                date: new Date(data.date), // convierte string -> Date
            },
        });
    }
    async findById(id) {
        return this.prisma.drivingClass.findUnique({ where: { id } });
    }
    async findAll() {
        return this.prisma.drivingClass.findMany();
    }
    async update(id, data) {
        return this.prisma.drivingClass.update({ where: { id }, data });
    }
    async delete(id) {
        await this.prisma.drivingClass.delete({ where: { id } });
    }
}
exports.PrismaDrivingClassRepository = PrismaDrivingClassRepository;
