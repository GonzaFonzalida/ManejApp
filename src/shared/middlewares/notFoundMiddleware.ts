import { Request, Response, NextFunction } from "express";
import NotFoundError from "../utils/classes/PageNotFoundError";

const notFoundHandler = (req: Request, res: Response, next: NextFunction) => {
    next(new NotFoundError(`La ruta ${req.host + req.originalUrl} no existe`));
};

export default notFoundHandler; 