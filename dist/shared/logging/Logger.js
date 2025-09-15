"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Logger = void 0;
const LogEntry_1 = require("./LogEntry");
class Logger {
    transports = [];
    minLevel = LogEntry_1.LogLevel.INFO;
    context = {};
    constructor(transports = [], minLevel = LogEntry_1.LogLevel.INFO) {
        this.transports = transports;
        this.minLevel = minLevel;
    }
    // Set global context that will be included in all logs
    setContext(context) {
        this.context = { ...this.context, ...context };
    }
    // Clear global context
    clearContext() {
        this.context = {};
    }
    // Create a child logger with additional context
    child(context) {
        const childLogger = new Logger(this.transports, this.minLevel);
        childLogger.context = { ...this.context, ...context };
        return childLogger;
    }
    // Log methods
    error(message, error, context, metadata) {
        this.log(LogEntry_1.LogLevel.ERROR, message, error, context, metadata);
    }
    warn(message, context, metadata) {
        this.log(LogEntry_1.LogLevel.WARN, message, undefined, context, metadata);
    }
    info(message, context, metadata) {
        this.log(LogEntry_1.LogLevel.INFO, message, undefined, context, metadata);
    }
    debug(message, context, metadata) {
        this.log(LogEntry_1.LogLevel.DEBUG, message, undefined, context, metadata);
    }
    // Generic log method
    log(level, message, error, context, metadata) {
        if (!this.shouldLog(level)) {
            return;
        }
        const entry = {
            timestamp: new Date(),
            level,
            message,
            context: { ...this.context, ...context },
            error: error ? this.serializeError(error) : undefined,
            metadata,
        };
        // Send to all transports
        this.transports.forEach(transport => {
            transport.log(entry).catch(err => {
                console.error('Transport error:', err);
            });
        });
    }
    shouldLog(level) {
        const levels = [LogEntry_1.LogLevel.ERROR, LogEntry_1.LogLevel.WARN, LogEntry_1.LogLevel.INFO, LogEntry_1.LogLevel.DEBUG];
        const currentLevelIndex = levels.indexOf(this.minLevel);
        const logLevelIndex = levels.indexOf(level);
        return logLevelIndex <= currentLevelIndex;
    }
    serializeError(error) {
        return {
            name: error.name,
            message: error.message,
            stack: error.stack,
            code: error.code,
        };
    }
    // Utility methods for common logging patterns
    logRequest(req, res, responseTime) {
        const context = {
            requestId: req.id || req.headers['x-request-id'],
            userId: req.user?.id,
            userRole: req.user?.role,
            ip: req.ip || req.connection.remoteAddress,
            userAgent: req.headers['user-agent'],
            method: req.method,
            url: req.originalUrl || req.url,
            statusCode: res.statusCode,
            responseTime,
        };
        const level = res.statusCode >= 400 ? LogEntry_1.LogLevel.WARN : LogEntry_1.LogLevel.INFO;
        const message = `${req.method} ${req.originalUrl || req.url} - ${res.statusCode} - ${responseTime}ms`;
        this.log(level, message, undefined, context);
    }
    logDatabaseQuery(query, duration, context) {
        this.debug('Database query executed', {
            ...context,
            module: 'database',
            responseTime: duration,
        }, { query });
    }
    logBusinessEvent(event, context, metadata) {
        this.info(`Business event: ${event}`, {
            ...context,
            module: 'business',
        }, metadata);
    }
    logSecurityEvent(event, context, metadata) {
        this.warn(`Security event: ${event}`, {
            ...context,
            module: 'security',
        }, metadata);
    }
    // Cleanup method
    async close() {
        await Promise.all(this.transports.map(transport => transport.close ? transport.close() : Promise.resolve()));
    }
}
exports.Logger = Logger;
