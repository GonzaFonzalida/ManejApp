import { Request, Response } from "express";
import AuthService from "./auth.services";
import { ExpressFunction } from "../shared/types/ExpressFunction";

export default class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * @swagger
   * /auth/login:
   *   post:
   *     summary: User login
   *     tags: [Authentication]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - email
   *               - password
   *             properties:
   *               email:
   *                 type: string
   *                 format: email
   *               password:
   *                 type: string
   *                 minLength: 6
   *     responses:
   *       200:
   *         description: Login successful
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 token:
   *                   type: string
   *                 user:
   *                   type: object
   *       400:
   *         description: Invalid credentials
   *       500:
   *         description: Internal server error
   */
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

  /**
   * @swagger
   * /auth/refresh:
   *   post:
   *     summary: Refresh access token
   *     tags: [Authentication]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: Token refreshed successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 token:
   *                   type: string
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  refresh : ExpressFunction = async (req, res, next) => {
    try {
      const result = await this.authService.refresh(req, res);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /auth/logout:
   *   post:
   *     summary: User logout
   *     tags: [Authentication]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: Logout successful
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 message:
   *                   type: string
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  logout : ExpressFunction = async (req, res, next) => {
    try {
      const result = await this.authService.logout(req, res);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /auth/me:
   *   get:
   *     summary: Get current user information
   *     tags: [Authentication]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: User information retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 user:
   *                   type: object
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  me : ExpressFunction = async (req, res, next) => {
    try {
      res.json({ user: (req as any).user });
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /auth/sessions:
   *   get:
   *     summary: Get user sessions
   *     tags: [Authentication]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: Sessions retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: array
   *               items:
   *                 type: object
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  sessions : ExpressFunction = async (req, res, next) => {
    try {
      const userId = (req as any).user.id;
      const sessions = await this.authService.listSessions(userId);
      res.json(sessions);
    } catch (err) {
      next(err);
    }
  };

  /**
   * @swagger
   * /auth/revoke/{sessionId}:
   *   post:
   *     summary: Revoke a specific session
   *     tags: [Authentication]
   *     security:
   *       - bearerAuth: []
   *     parameters:
   *       - in: path
   *         name: sessionId
   *         required: true
   *         schema:
   *           type: string
   *         description: Session ID to revoke
   *     responses:
   *       200:
   *         description: Session revoked successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 message:
   *                   type: string
   *       401:
   *         description: Unauthorized
   *       404:
   *         description: Session not found
   *       500:
   *         description: Internal server error
   */
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

  /**
   * @swagger
   * /auth/revoke-all:
   *   post:
   *     summary: Revoke all user sessions
   *     tags: [Authentication]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: All sessions revoked successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 message:
   *                   type: string
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
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
