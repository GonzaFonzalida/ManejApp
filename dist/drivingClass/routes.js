"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const GenericRouter_1 = __importDefault(require("../shared/classes/GenericRouter"));
const schemas_1 = require("./schemas");
const validateBody_1 = require("../shared/middlewares/zod/validateBody");
class DrivingClassRouter extends GenericRouter_1.default {
    drivingClassController;
    constructor(drivingClassController) {
        super();
        this.drivingClassController = drivingClassController;
        const router = this.init();
        router.get("/", this.drivingClassController.list);
        router.get("/:id", this.drivingClassController.getById);
        router.post("/", (0, validateBody_1.validate)(schemas_1.createDrivingClassSchema), this.drivingClassController.create);
        router.put("/:id", (0, validateBody_1.validate)(schemas_1.updateDrivingClassSchema), this.drivingClassController.update);
        router.patch("/:id/cancel", this.drivingClassController.cancel);
        router.delete("/:id", this.drivingClassController.delete);
    }
}
exports.default = DrivingClassRouter;
