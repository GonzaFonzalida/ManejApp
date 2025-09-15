/**
 * Sistema de Logging - Punto de Entrada Principal
 * 
 * Este archivo exporta todos los componentes necesarios del sistema de logging
 * y proporciona una interfaz unificada para su uso en toda la aplicación.
 */

// Exportar tipos principales
export { LogLevel, LogContext, LogEntry, LogTransport } from './LogEntry';

// Exportar clase principal del logger
export { Logger } from './Logger';

// Exportar factory y configuración
export { LoggerFactory, logger } from './LoggerConfig';

// Exportar transports
export { ConsoleTransport } from './transports/ConsoleTransport';
export { FileTransport, FileTransportConfig } from './transports/FileTransport';
export { DatabaseTransport, DatabaseTransportConfig } from './transports/DatabaseTransport';

// Exportar middlewares
export { 
  requestLoggerMiddleware, 
  errorLoggerMiddleware, 
  performanceLoggerMiddleware 
} from './middleware/requestLogger';

// Importar logger después de las exportaciones para evitar dependencias circulares
import { logger } from './LoggerConfig';

// Exportar utilidades de logging para casos específicos
export class LoggingUtils {
  /**
   * Crea un logger específico para un módulo
   */
  static createModuleLogger(moduleName: string) {
    return logger.child({ module: moduleName });
  }

  /**
   * Crea un logger específico para una operación
   */
  static createOperationLogger(operationName: string, context?: any) {
    return logger.child({
      operation: operationName,
      operationId: `op_${Date.now()}`,
      ...context
    });
  }

  /**
   * Log de eventos de negocio estandarizado
   */
  static logBusinessEvent(event: string, context?: any, metadata?: any) {
    logger.logBusinessEvent(event, context, metadata);
  }

  /**
   * Log de eventos de seguridad estandarizado
   */
  static logSecurityEvent(event: string, context?: any, metadata?: any) {
    logger.logSecurityEvent(event, context, metadata);
  }

  /**
   * Log de métricas de performance
   */
  static logPerformanceMetric(metric: string, value: number, context?: any) {
    logger.info(`Performance metric: ${metric}`, {
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
  static logDatabaseOperation(operation: string, duration: number, context?: any) {
    logger.logDatabaseQuery(operation, duration, {
      ...context,
      module: 'database',
    });
  }
}

// Inicialización del sistema de logging
export const initializeLogging = () => {
  logger.info('Sistema de logging inicializado', {
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

// Auto-inicialización del sistema
initializeLogging();