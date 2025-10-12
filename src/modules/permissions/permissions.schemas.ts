import { z } from "zod";

export const createPermissionSchema = z.object({
    name: z.string().min(1, "El nombre del permiso es requerido"),
    description: z.string().min(1, "La descripcion del permiso es requerida"),
    isMandatory: z.boolean(),
});

export const updatePermissionSchema = z.object({
    name: z.string().optional(),
    description: z.string().optional(),
    isMandatory: z.boolean().optional(),
});
