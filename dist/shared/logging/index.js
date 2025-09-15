"use strict";
/**
 * Sistema de Logging - Punto de Entrada Principal
 *
 * Este archivo exporta todos los componentes necesarios del sistema de logging
 * y proporciona una interfaz unificada para su uso en toda la aplicación.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.initializeLogging = exports.LoggingUtils = exports.performanceLoggerMiddleware = exports.errorLoggerMiddleware = exports.requestLoggerMiddleware = exports.DatabaseTransport = exports.FileTransport = exports.ConsoleTransport = exports.logger = exports.LoggerFactory = exports.Logger = exports.LogLevel = void 0;
// Exportar tipos principales
var LogEntry_1 = require("./LogEntry");
Object.defineProperty(exports, "LogLevel", { enumerable: true, get: function () { return LogEntry_1.LogLevel; } });
// Exportar clase principal del logger
var Logger_1 = require("./Logger");
Object.defineProperty(exports, "Logger", { enumerable: true, get: function () { return Logger_1.Logger; } });
// Exportar factory y configuración
var LoggerConfig_1 = require("./LoggerConfig");
Object.defineProperty(exports, "LoggerFactory", { enumerable: true, get: function () { return LoggerConfig_1.LoggerFactory; } });
Object.defineProperty(exports, "logger", { enumerable: true, get: function () { return LoggerConfig_1.logger; } });
// Exportar transports
var ConsoleTransport_1 = require("./transports/ConsoleTransport");
Object.defineProperty(exports, "ConsoleTransport", { enumerable: true, get: function () { return ConsoleTransport_1.ConsoleTransport; } });
var FileTransport_1 = require("./transports/FileTransport");
Object.defineProperty(exports, "FileTransport", { enumerable: true, get: function () { return FileTransport_1.FileTransport; } });
var DatabaseTransport_1 = require("./transports/DatabaseTransport");
Object.defineProperty(exports, "DatabaseTransport", { enumerable: true, get: function () { return DatabaseTransport_1.DatabaseTransport; } });
// Exportar middlewares
var requestLogger_1 = require("./middleware/requestLogger");
Object.defineProperty(exports, "requestLoggerMiddleware", { enumerable: true, get: function () { return requestLogger_1.requestLoggerMiddleware; } });
Object.defineProperty(exports, "errorLoggerMiddleware", { enumerable: true, get: function () { return requestLogger_1.errorLoggerMiddleware; } });
Object.defineProperty(exports, "performanceLoggerMiddleware", { enumerable: true, get: function () { return requestLogger_1.performanceLoggerMiddleware; } });
// Importar logger después de las exportaciones para evitar dependencias circulares
const LoggerConfig_2 = require("./LoggerConfig");
// Exportar utilidades de logging para casos específicos
class LoggingUtils {
    /**
     * Crea un logger específico para un módulo
     */
    static createModuleLogger(moduleName) {
        return LoggerConfig_2.logger.child({ module: moduleName });
    }
    /**
     * Crea un logger específico para una operación
     */
    static createOperationLogger(operationName, context) {
        return LoggerConfig_2.logger.child({
            operation: operationName,
            operationId: `op_${Date.now()}`,
            ...context
        });
    }
    /**
     * Log de eventos de negocio estandarizado
     */
    static logBusinessEvent(event, context, metadata) {
        LoggerConfig_2.logger.logBusinessEvent(event, context, metadata);
    }
    /**
     * Log de eventos de seguridad estandarizado
     */
    static logSecurityEvent(event, context, metadata) {
        LoggerConfig_2.logger.logSecurityEvent(event, context, metadata);
    }
    /**
     * Log de métricas de performance
     */
    static logPerformanceMetric(metric, value, context) {
        LoggerConfig_2.logger.info(`Performance metric: ${metric}`, {
            ...context,
            module: 'performance',
        }, {
            metric,
            value,
            unit: 'ms',
            timestamp: new Date().toISOString(),
        });
    }
    /**
     * Log de operaciones de base de datos
     */
    static logDatabaseOperation(operation, duration, context) {
        LoggerConfig_2.logger.logDatabaseQuery(operation, duration, {
            ...context,
            module: 'database',
        });
    }
}
exports.LoggingUtils = LoggingUtils;
// Inicialización del sistema de logging
const initializeLogging = () => {
    LoggerConfig_2.logger.info('Sistema de logging inicializado', {
        module: 'logging',
        function: 'initializeLogging',
    }, {
        transports: [
            process.env.ENABLE_CONSOLE_LOGS === 'true' ? 'console' : null,
            process.env.ENABLE_FILE_LOGS === 'true' ? 'file' : null,
            process.env.ENABLE_DATABASE_LOGS === 'true' ? 'database' : null,
        ].filter(Boolean),
        logLevel: process.env.LOG_LEVEL || 'info',
        environment: process.env.NODE_ENV || 'development',
    });
};
exports.initializeLogging = initializeLogging;
// Auto-inicialización del sistema
(0, exports.initializeLogging)();
