"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validate = void 0;
const validate = (schema) => (req, res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
        const message = result.error.issues
            .map((i) => `${i.path.length ? i.path.join(".") : "body"}: ${i.message}`)
            .join("; ") || "Solicitud inválida";
        return res.status(400).json({ message, error: result.error });
    }
    req.body = result.data;
    next();
};
exports.validate = validate;
