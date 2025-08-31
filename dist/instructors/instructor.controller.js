"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const CustomizedError_1 = __importDefault(require("../shared/classes/CustomizedError"));
class InstructorController {
    instructorService;
    constructor(instructorService) {
        this.instructorService = instructorService;
    }
    register = async (req, res, next) => {
        try {
            const instructor = await this.instructorService.registerInstructor(req.body);
            res.status(201).json(instructor);
        }
        catch (err) {
            next(err);
        }
    };
    updateProfile = async (req, res, next) => {
        const instructorId = Number(req.params.id);
        const updatedInstructor = await this.instructorService.updateInstructor(instructorId, req.body);
        if (!updatedInstructor) {
            return next(new CustomizedError_1.default("Instructor no encontrado", 404));
        }
        return res.json(updatedInstructor);
    };
    getProfile = async (req, res, next) => {
        const instructor = await this.instructorService.getInstructorProfile(Number(req.params.id));
        if (!instructor) {
            return next(new CustomizedError_1.default("Instructor no encontrado, ingrese un pefil valido", 404));
            ;
        }
        res.json(instructor);
    };
    list = async (_req, res) => {
        const instructors = await this.instructorService.listInstructors();
        res.json(instructors);
    };
}
exports.default = InstructorController;
