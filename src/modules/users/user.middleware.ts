import { ExpressFunction } from "@shared/types/ExpressFunction";
import { z } from "zod";

export const validate =
    (schema: z.ZodSchema): ExpressFunction =>
    (req, res, next) => {
        const result = schema.safeParse(req.body);
        if (!result.success) {
            const firstIssue = result.error.issues[0];
            const message = firstIssue ? `${firstIssue.path.join('.')}: ${firstIssue.message}` : 'Datos inválidos';
            return res.status(400).json({ message });
        }
        req.body = result.data;
        next();
};
