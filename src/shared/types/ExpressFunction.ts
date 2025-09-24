import { Response, NextFunction } from "express";
import { AuthenticatedRequest } from "./AuthenticatedRequest";

export type ExpressFunction = (req: AuthenticatedRequest, res: Response, next: NextFunction) => void;
