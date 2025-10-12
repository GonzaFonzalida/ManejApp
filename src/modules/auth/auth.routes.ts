import { Router } from "express";
import { authenticate } from "./auth.middlewares";
import AuthController from "./auth.controller";
import { validate } from "../../shared/middlewares/zod/validateBody";
import { loginSchema } from "./auth.schemas";

export default function buildAuthRouter(controller: AuthController) {
  const router = Router();

  router.post("/login", validate(loginSchema), controller.login);
  router.post("/refresh", controller.refresh); // usa cookie httpOnly
  router.post("/logout", controller.logout);

  router.get("/me", authenticate, controller.me);
  router.get("/sessions", authenticate, controller.sessions);
  router.post("/revoke/:sessionId", authenticate, controller.revokeSession);
  router.post("/revoke-all", authenticate, controller.revokeAll);

  return router;
}
