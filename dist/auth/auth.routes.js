"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = buildAuthRouter;
const express_1 = require("express");
const auth_middlewares_1 = require("./auth.middlewares");
const validateBody_1 = require("../shared/middlewares/zod/validateBody");
const auth_schemas_1 = require("./auth.schemas");
function buildAuthRouter(controller) {
    const router = (0, express_1.Router)();
    router.post("/login", (0, validateBody_1.validate)(auth_schemas_1.loginSchema), controller.login);
    router.post("/refresh", controller.refresh); // usa cookie httpOnly
    router.post("/logout", controller.logout);
    router.get("/me", auth_middlewares_1.authenticate, controller.me);
    router.get("/sessions", auth_middlewares_1.authenticate, controller.sessions);
    router.post("/revoke/:sessionId", auth_middlewares_1.authenticate, controller.revokeSession);
    router.post("/revoke-all", auth_middlewares_1.authenticate, controller.revokeAll);
    return router;
}
