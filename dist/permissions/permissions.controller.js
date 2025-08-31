"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PermissionController = void 0;
const CustomizedError_1 = __importDefault(require("../shared/classes/CustomizedError"));
class PermissionController {
    service;
    constructor(service) {
        this.service = service;
    }
    create = async (req, res, next) => {
        try {
            const { name, description, isMandatory } = req.body;
            if (!name || !description || typeof isMandatory !== "boolean") {
                return next(new CustomizedError_1.default("Invalid permission data", 400));
            }
            const permission = await this.service.createPermission({ name, description, isMandatory });
            return res.status(201).json(permission);
        }
        catch (error) {
            if (error instanceof CustomizedError_1.default) {
                return res.status(error.statusCode).json({ error: error.message });
            }
            else {
                return res.status(500).json({ error: "Internal Server Error" });
            }
        }
    };
    update = async (req, res, next) => {
        try {
            const userId = Number(req.params.id);
            const userChanges = req.body;
            if (isNaN(userId))
                throw new CustomizedError_1.default("El id es inválido", 400);
            if (!userChanges || Object.keys(userChanges).length === 0)
                throw new CustomizedError_1.default("Ingrese cambio a realizar por el body", 400);
            const updatedUser = await this.service.updatePermission(userId, userChanges);
            if (!updatedUser) {
                return next(new CustomizedError_1.default("El Permiso no se pudo actualizar", 404));
            }
            return res.json(updatedUser);
        }
        catch (error) {
            next(error); // Pasamos el error al middleware de manejo de errores
        }
    };
    getAll = async (req, res) => {
        const permissions = await this.service.getAllPermissions();
        res.json(permissions);
    };
    getById = async (req, res) => {
        const id = Number(req.params.id);
        if (isNaN(id))
            throw new CustomizedError_1.default("El id es invalido", 400);
        const permission = await this.service.getPermission(id);
        if (!permission)
            throw new CustomizedError_1.default("Permiso no encontrado", 404);
        res.json(permission);
    };
}
exports.PermissionController = PermissionController;
