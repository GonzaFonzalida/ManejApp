"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const CustomizedError_1 = __importDefault(require("../classes/CustomizedError"));
const LoggerConfig_1 = require("../logging/LoggerConfig");
const errorHandler = (err, req, res, next) => {
    const time = Date.now();
    const responseTime = time - (req.startTime || time);
    // Use request logger if available, otherwise use global logger
    const requestLogger = req.logger || LoggerConfig_1.logger;
    if (err instanceof CustomizedError_1.default) {
        // Log custom errors as warnings (they're expected errors)
        requestLogger.warn(`Custom error: ${err.message}`, {
            statusCode: err.statusCode,
            responseTime,
        }, {
            errorType: 'CustomizedError',
            host: req.host,
            url: req.originalUrl,
            method: req.method,
        });
        return res.status(err.statusCode).json({
            message: err.message,
            host: req.host,
            url: req.originalUrl,
            method: req.method,
            statusCode: err.statusCode,
            time: time,
        });
    }
    // Log unexpected errors as errors
    requestLogger.error(`Unhandled error: ${err.message}`, err, {
        statusCode: 500,
        responseTime,
    }, {
        errorType: 'UnhandledError',
        host: req.host,
        url: req.originalUrl,
        method: req.method,
    });
    return res.status(500).json({
        message: "Error interno del servidor",
        errorName: err.name,
        host: req.host,
        url: req.originalUrl,
        method: req.method,
        statusCode: 500,
        ok: false,
        time: time,
    });
};
exports.default = errorHandler;
