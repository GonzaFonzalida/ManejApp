"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const CustomizedError_1 = __importDefault(require("../shared/classes/CustomizedError"));
class InstructorService {
    instructorRepo;
    userRepo;
    permissionRepo;
    constructor(instructorRepo, userRepo, permissionRepo) {
        this.instructorRepo = instructorRepo;
        this.userRepo = userRepo;
        this.permissionRepo = permissionRepo;
    }
    async registerInstructor(data) {
        // 1. Verificar que exista el usuario
        const user = await this.userRepo.findUser(String(data.userId));
        if (!user)
            throw new CustomizedError_1.default("Usuario no encontrado", 404);
        if (user.role !== "STUDENT") {
            throw new Error("El usuario no puede registrarse como instructor");
        }
        const existingInstructor = await this.instructorRepo.getInstructorByUserId(data.userId);
        if (existingInstructor) {
            throw new CustomizedError_1.default("Este usuario ya es instructor", 409);
        }
        // 3. Crear el instructor
        const instructor = await this.instructorRepo.createInstructor(data);
        // 4. Obtener todos los permisos de la tabla Permission
        const permissions = await this.permissionRepo.findAll();
        // 5. Crear los registros en InstructorPermission
        for (const permission of permissions) {
            await this.instructorRepo.addPermission(instructor.id, permission.id);
        }
        return instructor;
    }
    async getInstructorProfile(id) {
        return this.instructorRepo.getInstructorById(id);
    }
    async listInstructors(filter) {
        return this.instructorRepo.listInstructors();
    }
    async updateInstructor(id, data) {
        return this.instructorRepo.updateInstructor(id, data);
    }
    async addPermission(instructorId, permissionId) {
        return this.instructorRepo.addPermission(instructorId, permissionId);
    }
    async validateIfHasAllPermissions(instructorId) {
        const hasAll = await this.instructorRepo.hasAllMandatoryPermissions(instructorId);
        if (hasAll) {
            return this.instructorRepo.validateInstructor(instructorId);
        }
        throw new CustomizedError_1.default("Instructor does not have all mandatory permissions", 400);
    }
}
exports.default = InstructorService;
