"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Logger = exports.LogLevel = exports.logger = exports.LoggerFactory = void 0;
const LogEntry_1 = require("./LogEntry");
const Logger_1 = require("./Logger");
const ConsoleTransport_1 = require("./transports/ConsoleTransport");
const FileTransport_1 = require("./transports/FileTransport");
const DatabaseTransport_1 = require("./transports/DatabaseTransport");
const config_1 = require("@config/config");
class LoggerFactory {
    static instance = null;
    static createLogger() {
        if (this.instance) {
            return this.instance;
        }
        const transports = [];
        // Console transport
        if (config_1.ENABLE_CONSOLE_LOGS) {
            transports.push(new ConsoleTransport_1.ConsoleTransport());
        }
        // File transport
        if (config_1.ENABLE_FILE_LOGS) {
            transports.push(new FileTransport_1.FileTransport({
                directory: config_1.LOG_DIRECTORY,
                filename: config_1.LOG_FILENAME,
                maxSize: config_1.LOG_MAX_SIZE,
                maxFiles: config_1.LOG_MAX_FILES,
            }));
        }
        // Database transport
        if (config_1.ENABLE_DATABASE_LOGS) {
            transports.push(new DatabaseTransport_1.DatabaseTransport({
                tableName: config_1.LOG_TABLE_NAME,
                retentionDays: config_1.LOG_RETENTION_DAYS,
            }));
        }
        // Set log level from configuration
        const logLevel = this.parseLogLevel(config_1.LOG_LEVEL);
        this.instance = new Logger_1.Logger(transports, logLevel);
        return this.instance;
    }
    static parseLogLevel(level) {
        switch (level.toLowerCase()) {
            case 'error':
                return LogEntry_1.LogLevel.ERROR;
            case 'warn':
                return LogEntry_1.LogLevel.WARN;
            case 'info':
                return LogEntry_1.LogLevel.INFO;
            case 'debug':
                return LogEntry_1.LogLevel.DEBUG;
            default:
                return LogEntry_1.LogLevel.INFO;
        }
    }
    // Get singleton instance
    static getInstance() {
        if (!this.instance) {
            this.instance = this.createLogger();
        }
        return this.instance;
    }
    // Reset instance (useful for testing)
    static reset() {
        if (this.instance) {
            this.instance.close();
            this.instance = null;
        }
    }
}
exports.LoggerFactory = LoggerFactory;
// Export singleton instance
exports.logger = LoggerFactory.getInstance();
// Export types for external use
var LogEntry_2 = require("./LogEntry");
Object.defineProperty(exports, "LogLevel", { enumerable: true, get: function () { return LogEntry_2.LogLevel; } });
var Logger_2 = require("./Logger");
Object.defineProperty(exports, "Logger", { enumerable: true, get: function () { return Logger_2.Logger; } });
