"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class AuthController {
    authService;
    constructor(authService) {
        this.authService = authService;
    }
    login = async (req, res, next) => {
        const { email, password } = req.body;
        const result = await this.authService.login(req, res, email, password);
        if (result instanceof Error) {
            return next(result);
        }
        return res.json(result);
    };
    refresh = async (req, res, next) => {
        const result = await this.authService.refresh(req, res);
        res.json(result);
    };
    logout = async (req, res, next) => {
        const result = await this.authService.logout(req, res);
        res.json(result);
    };
    me = async (req, res, next) => {
        res.json({ user: req.user });
    };
    sessions = async (req, res, next) => {
        const userId = req.user.id;
        const sessions = await this.authService.listSessions(userId);
        res.json(sessions);
    };
    revokeSession = async (req, res, next) => {
        const userId = req.user.id;
        const { sessionId } = req.params;
        const result = await this.authService.revokeSession(userId, sessionId);
        res.json(result);
    };
    revokeAll = async (req, res, next) => {
        const userId = req.user.id;
        const result = await this.authService.revokeAll(userId);
        res.json(result);
    };
}
exports.default = AuthController;
