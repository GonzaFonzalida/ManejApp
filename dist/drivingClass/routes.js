"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const zod_1 = require("zod");
const GenericRouter_1 = __importDefault(require("../shared/classes/GenericRouter"));
const schemas_1 = require("./schemas");
const validateBody_1 = require("../shared/middlewares/zod/validateBody");
const validateParams_1 = require("../shared/middlewares/zod/validateParams");
class DrivingClassRouter extends GenericRouter_1.default {
    drivingClassController;
    constructor(drivingClassController) {
        super();
        this.drivingClassController = drivingClassController;
    }
    init() {
        const router = super.init();
        // Esquema para validar parámetros ID
        const idParamSchema = zod_1.z.object({
            id: zod_1.z.string().regex(/^\d+$/, "ID debe ser un número").transform(Number)
        });
        router.get("/", this.drivingClassController.list);
        router.get("/:id", (0, validateParams_1.validateParams)(idParamSchema), this.drivingClassController.getById);
        router.post("/", (0, validateBody_1.validate)(schemas_1.createDrivingClassSchema), this.drivingClassController.create);
        router.put("/:id", (0, validateParams_1.validateParams)(idParamSchema), (0, validateBody_1.validate)(schemas_1.updateDrivingClassSchema), this.drivingClassController.update);
        router.patch("/:id/cancel", (0, validateParams_1.validateParams)(idParamSchema), this.drivingClassController.cancel);
        router.delete("/:id", (0, validateParams_1.validateParams)(idParamSchema), this.drivingClassController.delete);
        return router;
    }
}
exports.default = DrivingClassRouter;
