"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DrivingClassController = void 0;
class DrivingClassController {
    service;
    constructor(service) {
        this.service = service;
    }
    create = async (req, res) => {
        const drivingClass = await this.service.create(req.body);
        res.status(201).json(drivingClass);
    };
    list = async (req, res) => {
        const classes = await this.service.listClasses();
        res.json(classes);
    };
    getById = async (req, res) => {
        const cls = await this.service.getClassById(Number(req.params.id));
        if (!cls)
            return res.status(404).json({ message: "Class not found" });
        res.json(cls);
    };
    update = async (req, res) => {
        const cls = await this.service.updateClass(Number(req.params.id), req.body);
        res.json(cls);
    };
    cancel = async (req, res) => {
        await this.service.cancelClass(Number(req.params.id));
        res.status(204).send();
    };
    delete = async (req, res) => {
        await this.service.deleteClass(Number(req.params.id));
        res.status(204).send();
    };
}
exports.DrivingClassController = DrivingClassController;
