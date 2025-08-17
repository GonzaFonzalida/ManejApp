import { Request, Response } from "express";
import AuthService from "./auth.services";
import { ExpressFunction } from "../shared/types/ExpressFunction";

export default class AuthController {
  constructor(private readonly authService: AuthService) {}

  login : ExpressFunction = async (req, res, next) => {
    const { email, password } = req.body;
    const result = await this.authService.login(req, res, email, password);
    res.json(result);
  };

  refresh : ExpressFunction = async (req, res, next) => {
    const result = await this.authService.refresh(req, res);
    res.json(result);
  };

  logout : ExpressFunction = async (req, res, next) => {
    const result = await this.authService.logout(req, res);
    res.json(result);
  };

  me : ExpressFunction = async (req, res, next) => {
    res.json({ user: (req as any).user });
  };

  sessions : ExpressFunction = async (req, res, next) => {
    const userId = (req as any).user.id;
    const sessions = await this.authService.listSessions(userId);
    res.json(sessions);
  };

  revokeSession : ExpressFunction = async (req, res, next) => {
    const userId = (req as any).user.id;
    const { sessionId } = req.params;
    const result = await this.authService.revokeSession(userId, sessionId);
    res.json(result);
  };

  revokeAll : ExpressFunction = async (req, res, next) => {
    const userId = (req as any).user.id;
    const result = await this.authService.revokeAll(userId);
    res.json(result);
  };
}
