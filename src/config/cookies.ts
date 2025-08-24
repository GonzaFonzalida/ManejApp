import { NODE_ENV } from "./config";
export const REFRESH_COOKIE_NAME: string = "refreshToken";

export const refreshCookieOptions = {
  httpOnly: true,
  secure: NODE_ENV === "production",
  sameSite: "strict" as const,
  path: "/auth/refresh",     // Sólo se envía en este endpoint
  maxAge: 1000 * 60 * 60 * 24 * 30, // 30 días
};
