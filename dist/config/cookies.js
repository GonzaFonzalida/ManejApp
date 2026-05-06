"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.refreshCookieOptions = exports.REFRESH_COOKIE_NAME = void 0;
const config_1 = require("./config");
exports.REFRESH_COOKIE_NAME = "refreshToken";
exports.refreshCookieOptions = {
    httpOnly: true,
    secure: config_1.NODE_ENV === "production",
    sameSite: "strict",
    path: "/api/v1/auth/refresh",
    maxAge: 1000 * 60 * 60 * 24 * 30, // 30 días
};
