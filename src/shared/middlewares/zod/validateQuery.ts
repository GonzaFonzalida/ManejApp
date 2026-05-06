import { Request, Response, NextFunction } from "express";
import { z } from "zod";

export const validateQuery =
  (schema: z.ZodSchema) => (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.query);
    if (!result.success) {
      const firstIssue = result.error.issues[0];
      const message = firstIssue ? `${firstIssue.path.join(".")}: ${firstIssue.message}` : "Query inválido";
      return res.status(422).json({ message });
    }
    (req as any).validatedQuery = result.data;
    next();
  };
