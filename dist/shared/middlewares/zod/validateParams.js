"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validateParams = void 0;
const validateParams = (schema) => (req, res, next) => {
    try {
        schema.parse(req.params);
        next();
    }
    catch (error) {
        res.status(400).json(JSON.parse(error.message));
    }
};
exports.validateParams = validateParams;
