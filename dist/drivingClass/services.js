"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.DrivingClassService = void 0;
const prismaClient_1 = require("../config/prismaClient");
const CustomizedError_1 = __importDefault(require("../shared/classes/CustomizedError"));
class DrivingClassService {
    userRepo;
    instructorRepo;
    drivingClassRepo;
    constructor(userRepo, instructorRepo, drivingClassRepo) {
        this.userRepo = userRepo;
        this.instructorRepo = instructorRepo;
        this.drivingClassRepo = drivingClassRepo;
    }
    async create(data) {
        try {
            // Validar que el estudiante exista en Student
            const studentExists = await prismaClient_1.prisma.student.findUnique({
                where: { id: data.studentId }
            });
            if (!studentExists)
                throw new CustomizedError_1.default("El estudiante no existe", 409);
            // Validar que el instructor exista
            const instructorExists = await prismaClient_1.prisma.instructor.findUnique({
                where: { id: data.instructorId }
            });
            if (!instructorExists)
                throw new CustomizedError_1.default("El instructor no existe", 409);
            // Crear la clase
            return await prismaClient_1.prisma.drivingClass.create({
                data: {
                    studentId: data.studentId,
                    instructorId: data.instructorId,
                    date: new Date(data.date),
                    duration: data.duration,
                    status: data.status,
                }
            });
        }
        catch (e) {
            if (e.code === "P2003") {
                throw new CustomizedError_1.default("Violación de clave foránea: estudiante o instructor no existe", 409);
            }
            throw e;
        }
    }
    async listClasses() {
        return this.drivingClassRepo.findAll();
    }
    async getClassById(id) {
        return this.drivingClassRepo.findById(id);
    }
    async updateClass(id, data) {
        return this.drivingClassRepo.update(id, data);
    }
    async cancelClass(id) {
        await this.drivingClassRepo.update(id, { status: "cancelled" });
    }
    async deleteClass(id) {
        await this.drivingClassRepo.delete(id);
    }
}
exports.DrivingClassService = DrivingClassService;
