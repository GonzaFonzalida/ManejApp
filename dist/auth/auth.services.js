"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jwtUtils_1 = require("../shared/utils/jwtUtils");
const cookies_1 = require("../config/cookies");
const CustomizedError_1 = __importDefault(require("../shared/classes/CustomizedError"));
class AuthService {
    sessions;
    users;
    constructor(sessions, users) {
        this.sessions = sessions;
        this.users = users;
    }
    async login(req, res, email, password) {
        const user = await this.users.findByEmail(email);
        if (!user)
            return new CustomizedError_1.default("Email no encontrado", 401);
        const ok = await bcryptjs_1.default.compare(password, user.password);
        if (!ok)
            return new CustomizedError_1.default("Contraseña Incorrecta", 401);
        const accessToken = (0, jwtUtils_1.signAccessToken)({ id: user.id, role: user.role });
        const refreshToken = (0, jwtUtils_1.signRefreshToken)({ id: user.id, role: user.role });
        // Guarda la sesión (hash del refresh)
        const refreshHash = await bcryptjs_1.default.hash(refreshToken, 10);
        const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30);
        await this.sessions.create({
            userId: user.id,
            refreshHash,
            userAgent: req.headers["user-agent"],
            ip: req.ip,
            expiresAt,
        });
        // Set cookie httpOnly con el refresh token
        res.cookie(cookies_1.REFRESH_COOKIE_NAME, refreshToken, cookies_1.refreshCookieOptions);
        await this.users.updateLastLoginAt(user.id);
        return { accessToken, user: this.stripUser(user) };
    }
    async refresh(req, res) {
        const token = req.cookies?.[cookies_1.REFRESH_COOKIE_NAME];
        if (!token)
            throw new Error("Refresh token no encontrado");
        const payload = (0, jwtUtils_1.verifyRefreshToken)(token);
        // Validar sesión en BD comparando el hash
        const allSessions = await this.sessions.findValidByUser(payload.id);
        let match = null;
        for (const s of allSessions) {
            const ok = await bcryptjs_1.default.compare(token, s.refreshHash);
            if (ok) {
                match = s;
                break;
            }
        }
        if (!match)
            throw new Error("Refresh token inválido");
        const accessToken = (0, jwtUtils_1.signAccessToken)({ id: payload.id, role: payload.role });
        // (Opcional) Rotación de refresh token:
        const newRefresh = (0, jwtUtils_1.signRefreshToken)({ id: payload.id, role: payload.role });
        const newHash = await bcryptjs_1.default.hash(newRefresh, 10);
        // Revoca la sesión anterior y crea una nueva (rotación estricta)
        await this.sessions.revokeById(match.id);
        await this.sessions.create({
            userId: payload.id,
            refreshHash: newHash,
            userAgent: req.headers["user-agent"],
            ip: req.ip,
            expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 24 * 30),
        });
        res.cookie(cookies_1.REFRESH_COOKIE_NAME, newRefresh, cookies_1.refreshCookieOptions);
        return { accessToken };
    }
    async logout(req, res) {
        const token = req.cookies?.[cookies_1.REFRESH_COOKIE_NAME];
        if (token) {
            const payload = (0, jwtUtils_1.verifyRefreshToken)(token);
            // Revocar la sesión que corresponda a este refresh
            const sessions = await this.sessions.findValidByUser(payload.id);
            for (const s of sessions) {
                const ok = await bcryptjs_1.default.compare(token, s.refreshHash);
                if (ok) {
                    await this.sessions.revokeById(s.id);
                    break;
                }
            }
        }
        res.clearCookie(cookies_1.REFRESH_COOKIE_NAME, { path: cookies_1.refreshCookieOptions.path });
        return { ok: true };
    }
    async listSessions(userId) {
        return this.sessions.findValidByUser(userId);
    }
    async revokeSession(userId, sessionId) {
        const s = await this.sessions.findById(sessionId);
        if (!s || s.userId !== userId)
            throw new Error("Sesión no encontrada");
        await this.sessions.revokeById(sessionId);
        return { ok: true };
    }
    async revokeAll(userId) {
        await this.sessions.revokeAllByUser(userId);
        return { ok: true };
    }
    stripUser(user) {
        const { password, ...rest } = user;
        return rest;
    }
}
exports.default = AuthService;
