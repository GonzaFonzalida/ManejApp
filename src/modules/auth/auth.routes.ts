import { Router } from "express";
import { authenticate } from "./auth.middlewares";
import AuthController from "./auth.controller";
import { validate } from "@shared/middlewares/zod/validateBody";
import { loginSchema, googleLoginSchema, appleLoginSchema } from "./auth.schemas";
import { authRateLimit } from "@middlewares/security";

export default function buildAuthRouter(controller: AuthController) {
  const router = Router();

  router.post("/login", authRateLimit, validate(loginSchema), controller.login);
  router.post("/google", authRateLimit, validate(googleLoginSchema), controller.googleLogin);
  router.post("/apple", authRateLimit, validate(appleLoginSchema), controller.appleLogin);
  router.post("/refresh", authRateLimit, controller.refresh); // usa cookie httpOnly
  router.post("/logout", controller.logout);

  router.get("/me", authenticate, controller.me);
  router.get("/sessions", authenticate, controller.sessions);
  router.post("/revoke/:sessionId", authenticate, controller.revokeSession);
  router.post("/revoke-all", authenticate, controller.revokeAll);

  return router;
}
