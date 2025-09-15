"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConsoleTransport = void 0;
const LogEntry_1 = require("../LogEntry");
class ConsoleTransport {
    colors = {
        [LogEntry_1.LogLevel.ERROR]: '\x1b[31m', // Red
        [LogEntry_1.LogLevel.WARN]: '\x1b[33m', // Yellow
        [LogEntry_1.LogLevel.INFO]: '\x1b[36m', // Cyan
        [LogEntry_1.LogLevel.DEBUG]: '\x1b[37m', // White
    };
    reset = '\x1b[0m';
    async log(entry) {
        const color = this.colors[entry.level];
        const timestamp = entry.timestamp.toISOString();
        const level = entry.level.toUpperCase().padEnd(5);
        let logMessage = `${color}[${timestamp}] ${level}${this.reset} ${entry.message}`;
        // Add context information
        if (entry.context) {
            const contextInfo = this.formatContext(entry.context);
            if (contextInfo) {
                logMessage += `\n  Context: ${contextInfo}`;
            }
        }
        // Add error details
        if (entry.error) {
            logMessage += `\n  Error: ${entry.error.name}: ${entry.error.message}`;
            if (entry.error.stack && entry.level === LogEntry_1.LogLevel.ERROR) {
                logMessage += `\n  Stack: ${entry.error.stack}`;
            }
        }
        // Add metadata
        if (entry.metadata && Object.keys(entry.metadata).length > 0) {
            logMessage += `\n  Metadata: ${JSON.stringify(entry.metadata, null, 2)}`;
        }
        console.log(logMessage);
    }
    formatContext(context) {
        const parts = [];
        if (context.requestId)
            parts.push(`reqId=${context.requestId}`);
        if (context.userId)
            parts.push(`userId=${context.userId}`);
        if (context.method && context.url)
            parts.push(`${context.method} ${context.url}`);
        if (context.statusCode)
            parts.push(`status=${context.statusCode}`);
        if (context.responseTime)
            parts.push(`${context.responseTime}ms`);
        if (context.ip)
            parts.push(`ip=${context.ip}`);
        if (context.module)
            parts.push(`module=${context.module}`);
        if (context.function)
            parts.push(`fn=${context.function}`);
        return parts.join(' | ');
    }
}
exports.ConsoleTransport = ConsoleTransport;
