import jwt from "jsonwebtoken";
import { randomUUID } from "crypto";
import { JWT_SECRET, JWT_REFRESH_SECRET, JWT_REFRESH_EXPIRATION } from "@config/config";

type JwtPayload = { id: number; role: string };

export const signAccessToken = (payload: JwtPayload) =>
  jwt.sign(payload, JWT_SECRET, { expiresIn:"15m" });

export const signRefreshToken = (payload: JwtPayload) =>
  jwt.sign({ ...payload, jti: randomUUID() }, JWT_REFRESH_SECRET, { expiresIn: "7d" });

export const verifyAccessToken = (token: string) =>
  jwt.verify(token, JWT_SECRET) as JwtPayload;

export const verifyRefreshToken = (token: string) =>
  jwt.verify(token, JWT_REFRESH_SECRET) as JwtPayload;
