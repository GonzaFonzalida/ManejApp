import { Request, Response } from "express";
import AuthService from "./auth.services";
import { ExpressFunction } from "../shared/types/ExpressFunction";

export default class AuthController {
  constructor(private readonly authService: AuthService) {}

  login : ExpressFunction = async (req, res, next) => {
    try {
      const { email, password } = req.body;
      const result = await this.authService.login(req, res, email, password);
      if (result instanceof Error) {
        return next(result);
      }
      return res.json(result);
    } catch (err) {
      next(err);
    }
  };

  refresh : ExpressFunction = async (req, res, next) => {
    try {
      const result = await this.authService.refresh(req, res);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  logout : ExpressFunction = async (req, res, next) => {
    try {
      const result = await this.authService.logout(req, res);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  me : ExpressFunction = async (req, res, next) => {
    try {
      res.json({ user: (req as any).user });
    } catch (err) {
      next(err);
    }
  };

  sessions : ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user.id;
      const sessions = await this.authService.listSessions(userId);
      res.json(sessions);
    } catch (err) {
      next(err);
    }
  };

  revokeSession : ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user.id;
      const { sessionId } = req.params;
      const result = await this.authService.revokeSession(userId, sessionId);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  revokeAll : ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user.id;
      const result = await this.authService.revokeAll(userId);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };
}
