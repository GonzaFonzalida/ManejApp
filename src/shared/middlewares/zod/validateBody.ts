import { ExpressFunction } from "../../types/ExpressFunction";
import { z } from "zod";

export const validate =
    (schema: z.ZodSchema): ExpressFunction =>
    (req, res, next) => {
        const result = schema.safeParse(req.body);
        if (!result.success) {
            return res.status(400).json({ error: result.error });
        }
        req.body = result.data;
        next();
};
