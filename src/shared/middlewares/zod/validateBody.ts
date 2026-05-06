import { ExpressFunction } from "../../types/ExpressFunction";
import { z } from "zod";

export const validate =
    (schema: z.ZodSchema): ExpressFunction =>
    (req, res, next) => {
        const result = schema.safeParse(req.body);
        if (!result.success) {
            const message =
                result.error.issues
                    .map((i) => `${i.path.length ? i.path.join(".") : "body"}: ${i.message}`)
                    .join("; ") || "Solicitud inválida";
            return res.status(400).json({ message, error: result.error });
        }
        req.body = result.data;
        next();
};
