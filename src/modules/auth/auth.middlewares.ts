import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { JWT_SECRET } from "@config/config";
import { prisma } from "@config/prismaClient";

export const authenticate = async (req: Request, res: Response, next: NextFunction) => {
  const auth = req.headers.authorization;
  if (!auth?.startsWith("Bearer ")) return res.status(401).json({ error: "No autorizado" });
  const token = auth.split(" ")[1];

  try {
    const payload = jwt.verify(token, JWT_SECRET) as { id: number; role: string };
    const row = await prisma.user.findUnique({
      where: { id: payload.id },
      select: { accountDeletedAt: true, isActive: true },
    });
    if (!row || row.accountDeletedAt != null || !row.isActive) {
      return res.status(401).json({ error: "No autorizado" });
    }
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
