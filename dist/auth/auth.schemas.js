"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.revokeSessionSchema = exports.refreshSchema = exports.loginSchema = void 0;
const zod_1 = require("zod");
exports.loginSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(6),
});
exports.refreshSchema = zod_1.z.object({}); // no body; cookie httpOnly
exports.revokeSessionSchema = zod_1.z.object({
    sessionId: zod_1.z.string().uuid(),
});
