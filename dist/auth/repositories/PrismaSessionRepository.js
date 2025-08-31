"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const prismaClient_1 = require("../../config/prismaClient");
class PrismaSessionRepository {
    prisma = prismaClient_1.prisma;
    constructor() { }
    async create(params) {
        return await this.prisma.session.create({ data: params });
    }
    async deleteSession(id) {
        return await this.prisma.session.delete({
            where: { id },
        });
    }
    async deleteSessionsByUser(userId) {
        return await this.prisma.session.deleteMany({
            where: { userId },
        });
    }
    async findById(id) {
        return await this.prisma.session.findUnique({ where: { id } });
    }
    async findValidByUser(userId) {
        return await this.prisma.session.findMany({
            where: { userId, revokedAt: null, expiresAt: { gt: new Date() } },
            orderBy: { createdAt: "desc" },
        });
    }
    async revokeById(id) {
        return await this.prisma.session.update({ where: { id }, data: { revokedAt: new Date() } }).then(() => { });
    }
    async revokeAllByUser(userId) {
        return await this.prisma.session.updateMany({
            where: { userId, revokedAt: null },
            data: { revokedAt: new Date() },
        }).then(() => { });
    }
    async findByHash(refreshHash) {
        return await this.prisma.session.findFirst({
            where: { refreshHash, revokedAt: null, expiresAt: { gt: new Date() } },
        });
    }
}
exports.default = PrismaSessionRepository;
