"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class AuthController {
    authService;
    constructor(authService) {
        this.authService = authService;
    }
    login = async (req, res, next) => {
        try {
            const { email, password } = req.body;
            const result = await this.authService.login(req, res, email, password);
            if (result instanceof Error) {
                return next(result);
            }
            return res.json(result);
        }
        catch (err) {
            next(err);
        }
    };
    refresh = async (req, res, next) => {
        try {
            const result = await this.authService.refresh(req, res);
            res.json(result);
        }
        catch (err) {
            next(err);
        }
    };
    logout = async (req, res, next) => {
        try {
            const result = await this.authService.logout(req, res);
            res.json(result);
        }
        catch (err) {
            next(err);
        }
    };
    me = async (req, res, next) => {
        try {
            res.json({ user: req.user });
        }
        catch (err) {
            next(err);
        }
    };
    sessions = async (req, res, next) => {
        try {
            const userId = req.user.id;
            const sessions = await this.authService.listSessions(userId);
            res.json(sessions);
        }
        catch (err) {
            next(err);
        }
    };
    revokeSession = async (req, res, next) => {
        try {
            const userId = req.user.id;
            const { sessionId } = req.params;
            const result = await this.authService.revokeSession(userId, sessionId);
            res.json(result);
        }
        catch (err) {
            next(err);
        }
    };
    revokeAll = async (req, res, next) => {
        try {
            const userId = req.user.id;
            const result = await this.authService.revokeAll(userId);
            res.json(result);
        }
        catch (err) {
            next(err);
        }
    };
}
exports.default = AuthController;
