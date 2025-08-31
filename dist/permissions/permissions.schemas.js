"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updatePermissionSchema = exports.createPermissionSchema = void 0;
const zod_1 = require("zod");
exports.createPermissionSchema = zod_1.z.object({
    name: zod_1.z.string().min(1, "El nombre del permiso es requerido"),
    description: zod_1.z.string().min(1, "La descripcion del permiso es requerida"),
    isMandatory: zod_1.z.boolean(),
});
exports.updatePermissionSchema = zod_1.z.object({
    name: zod_1.z.string().optional(),
    description: zod_1.z.string().optional(),
    isMandatory: zod_1.z.boolean().optional(),
});
