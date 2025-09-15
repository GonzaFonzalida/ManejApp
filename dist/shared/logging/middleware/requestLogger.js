"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.performanceLoggerMiddleware = exports.errorLoggerMiddleware = exports.requestLoggerMiddleware = void 0;
const crypto_1 = require("crypto");
const LoggerConfig_1 = require("../LoggerConfig");
const requestLoggerMiddleware = (req, res, next) => {
    // Generate unique request ID
    req.id = req.headers['x-request-id'] || (0, crypto_1.randomUUID)();
    req.startTime = Date.now();
    // Create child logger with request context
    req.logger = LoggerConfig_1.logger.child({
        requestId: req.id,
        userId: req.user?.id,
        userRole: req.user?.role,
        ip: req.ip || req.connection.remoteAddress,
        userAgent: req.headers['user-agent'],
        method: req.method,
        url: req.originalUrl || req.url,
    });
    // Log incoming request
    req.logger.info(`Incoming request: ${req.method} ${req.originalUrl || req.url}`, {
        headers: filterSensitiveHeaders(req.headers),
        query: req.query,
        body: filterSensitiveBody(req.body),
    });
    // Override res.json to log response
    const originalJson = res.json;
    res.json = function (body) {
        const responseTime = Date.now() - (req.startTime || Date.now());
        // Log response
        req.logger?.logRequest(req, res, responseTime);
        // Log response body for errors or debug level
        if (res.statusCode >= 400) {
            req.logger?.warn('Error response', {
                statusCode: res.statusCode,
                responseTime,
            }, {
                responseBody: filterSensitiveBody(body),
            });
        }
        else if (process.env.LOG_LEVEL === 'debug') {
            req.logger?.debug('Response sent', {
                statusCode: res.statusCode,
                responseTime,
            }, {
                responseBody: filterSensitiveBody(body),
            });
        }
        return originalJson.call(this, body);
    };
    // Override res.send to log response
    const originalSend = res.send;
    res.send = function (body) {
        const responseTime = Date.now() - (req.startTime || Date.now());
        // Log response if not already logged by res.json
        if (!res.headersSent) {
            req.logger?.logRequest(req, res, responseTime);
        }
        return originalSend.call(this, body);
    };
    next();
};
exports.requestLoggerMiddleware = requestLoggerMiddleware;
// Filter sensitive information from headers
function filterSensitiveHeaders(headers) {
    const filtered = { ...headers };
    const sensitiveHeaders = [
        'authorization',
        'cookie',
        'x-api-key',
        'x-auth-token',
    ];
    sensitiveHeaders.forEach(header => {
        if (filtered[header]) {
            filtered[header] = '[FILTERED]';
        }
    });
    return filtered;
}
// Filter sensitive information from request/response body
function filterSensitiveBody(body) {
    if (!body || typeof body !== 'object') {
        return body;
    }
    const filtered = Array.isArray(body) ? [...body] : { ...body };
    const sensitiveFields = [
        'password',
        'token',
        'secret',
        'key',
        'authorization',
        'creditCard',
        'ssn',
        'dni',
    ];
    const filterObject = (obj) => {
        if (!obj || typeof obj !== 'object') {
            return obj;
        }
        if (Array.isArray(obj)) {
            return obj.map(filterObject);
        }
        const result = { ...obj };
        Object.keys(result).forEach(key => {
            const lowerKey = key.toLowerCase();
            if (sensitiveFields.some(field => lowerKey.includes(field))) {
                result[key] = '[FILTERED]';
            }
            else if (typeof result[key] === 'object') {
                result[key] = filterObject(result[key]);
            }
        });
        return result;
    };
    return filterObject(filtered);
}
// Error logging middleware
const errorLoggerMiddleware = (error, req, res, next) => {
    const responseTime = Date.now() - (req.startTime || Date.now());
    // Log error with full context
    req.logger?.error(`Request failed: ${error.message}`, error, {
        statusCode: res.statusCode || 500,
        responseTime,
    }, {
        requestBody: filterSensitiveBody(req.body),
        requestQuery: req.query,
        requestParams: req.params,
    });
    next(error);
};
exports.errorLoggerMiddleware = errorLoggerMiddleware;
// Performance monitoring middleware
const performanceLoggerMiddleware = (threshold = 1000) => {
    return (req, res, next) => {
        const originalEnd = res.end;
        res.end = function (...args) {
            const responseTime = Date.now() - (req.startTime || Date.now());
            if (responseTime > threshold) {
                req.logger?.warn(`Slow request detected`, {
                    responseTime,
                    threshold,
                });
            }
            return originalEnd.apply(this, args);
        };
        next();
    };
};
exports.performanceLoggerMiddleware = performanceLoggerMiddleware;
