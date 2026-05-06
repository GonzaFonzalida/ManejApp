"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
class CustomizedError extends Error {
    statusCode;
    isOperational;
    /** Datos extra para el cliente (ej. missing[] en 422). */
    payload;
    constructor(message, statusCode = 500, payload) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = true;
        this.payload = payload;
        Error.captureStackTrace(this, this.constructor);
    }
}
exports.default = CustomizedError;
