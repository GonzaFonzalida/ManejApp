
import { Request, Response, NextFunction } from "express";
import { ZodObject } from "zod";

export const validateParams =
  (schema: ZodObject) => (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse(req.params);
      next();
    } catch (error: any) {
      res.status(400).json(JSON.parse(error.message));
    }
  };
