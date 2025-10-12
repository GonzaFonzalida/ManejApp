import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { JWT_SECRET } from "../../config/config";

export const authenticate = (req: Request, res: Response, next: NextFunction) => {
  const auth = req.headers.authorization;
  if (!auth?.startsWith("Bearer ")) return res.status(401).json({ error: "No autorizado" });
  const token = auth.split(" ")[1];

  try {
    const payload = jwt.verify(token, JWT_SECRET) as { id: number; role: string };
    (req as any).user = payload;
    next();
  } catch {
    return res.status(401).json({ error: "Token inválido" });
  }
};

export const requireRole = (...roles: string[]) =>
  (req: Request, res: Response, next: NextFunction) => {
    const user = (req as any).user;
    if (!user || !roles.includes(user.role)) {
      return res.status(403).json({ error: "Prohibido" });
    }
    next();
  };
