"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const config = __importStar(require("../../config/prismaClient"));
class PrismaInstructorRepository {
    constructor() { }
    prisma = config.prisma;
    async createInstructor(data) {
        return await this.prisma.instructor.create({
            data: {
                userId: data.userId,
                licenseNumber: data.licenseNumber,
                experienceYears: data.experienceYears,
            },
        });
    }
    async getInstructorById(id) {
        return await this.prisma.instructor.findUnique({
            where: { id },
            include: { permissions: true, cars: true, user: true },
        });
    }
    async getInstructorByUserId(userId) {
        return await this.prisma.instructor.findUnique({ where: { userId } });
    }
    async listInstructors(filter) {
        return await this.prisma.instructor.findMany({
            where: filter,
            include: { permissions: true, cars: true, user: true },
        });
    }
    async updateInstructor(id, data) {
        return this.prisma.instructor.update({
            where: { id },
            data,
        });
    }
    async addPermission(instructorId, permissionId) {
        await this.prisma.instructorPermission.upsert({
            where: { instructorId_permissionId: { instructorId, permissionId } },
            update: { granted: true },
            create: { instructorId, permissionId, granted: false },
        });
    }
    async removePermission(instructorId, permissionId) {
        await this.prisma.instructorPermission.delete({
            where: { instructorId_permissionId: { instructorId, permissionId } },
        });
    }
    async registerPermission(instructorId, permissionId) {
        const data = {
            instructorId,
            permissionId,
            granted: false
        };
        await this.prisma.instructorPermission.create({
            data
        });
    }
    async validateInstructor(instructorId) {
        return await this.prisma.instructor.update({
            where: { id: instructorId },
            data: { isValid: true },
        });
    }
    async hasAllMandatoryPermissions(instructorId) {
        const permissions = await this.prisma.instructorPermission.findMany({
            where: { instructorId },
            include: { permission: true },
        });
        return permissions
            .filter(p => p.permission.isMandatory)
            .every(p => p.granted);
    }
}
exports.default = PrismaInstructorRepository;
