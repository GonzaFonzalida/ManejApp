import { LogLevel, LogEntry, LogContext, LogTransport } from './LogEntry';

export class Logger {
  private transports: LogTransport[] = [];
  private minLevel: LogLevel = LogLevel.INFO;
  private context: LogContext = {};

  constructor(transports: LogTransport[] = [], minLevel: LogLevel = LogLevel.INFO) {
    this.transports = transports;
    this.minLevel = minLevel;
  }

  // Set global context that will be included in all logs
  setContext(context: LogContext): void {
    this.context = { ...this.context, ...context };
  }

  // Clear global context
  clearContext(): void {
    this.context = {};
  }

  // Create a child logger with additional context
  child(context: LogContext): Logger {
    const childLogger = new Logger(this.transports, this.minLevel);
    childLogger.context = { ...this.context, ...context };
    return childLogger;
  }

  // Log methods
  error(message: string, error?: Error, context?: LogContext, metadata?: Record<string, any>): void {
    this.log(LogLevel.ERROR, message, error, context, metadata);
  }

  warn(message: string, context?: LogContext, metadata?: Record<string, any>): void {
    this.log(LogLevel.WARN, message, undefined, context, metadata);
  }

  info(message: string, context?: LogContext, metadata?: Record<string, any>): void {
    this.log(LogLevel.INFO, message, undefined, context, metadata);
  }

  debug(message: string, context?: LogContext, metadata?: Record<string, any>): void {
    this.log(LogLevel.DEBUG, message, undefined, context, metadata);
  }

  // Generic log method
  private log(
    level: LogLevel,
    message: string,
    error?: Error,
    context?: LogContext,
    metadata?: Record<string, any>
  ): void {
    if (!this.shouldLog(level)) {
      return;
    }

    const entry: LogEntry = {
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

  private shouldLog(level: LogLevel): boolean {
    const levels = [LogLevel.ERROR, LogLevel.WARN, LogLevel.INFO, LogLevel.DEBUG];
    const currentLevelIndex = levels.indexOf(this.minLevel);
    const logLevelIndex = levels.indexOf(level);
    
    return logLevelIndex <= currentLevelIndex;
  }

  private serializeError(error: Error): { name: string; message: string; stack?: string; code?: string | number } {
    return {
      name: error.name,
      message: error.message,
      stack: error.stack,
      code: (error as any).code,
    };
  }

  // Utility methods for common logging patterns
  logRequest(req: any, res: any, responseTime: number): void {
    const context: LogContext = {
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

    const level = res.statusCode >= 400 ? LogLevel.WARN : LogLevel.INFO;
    const message = `${req.method} ${req.originalUrl || req.url} - ${res.statusCode} - ${responseTime}ms`;
    
    this.log(level, message, undefined, context);
  }

  logDatabaseQuery(query: string, duration: number, context?: LogContext): void {
    this.debug('Database query executed', {
      ...context,
      module: 'database',
      responseTime: duration,
    }, { query });
  }

  logBusinessEvent(event: string, context?: LogContext, metadata?: Record<string, any>): void {
    this.info(`Business event: ${event}`, {
      ...context,
      module: 'business',
    }, metadata);
  }

  logSecurityEvent(event: string, context?: LogContext, metadata?: Record<string, any>): void {
    this.warn(`Security event: ${event}`, {
      ...context,
      module: 'security',
    }, metadata);
  }

  // Cleanup method
  async close(): Promise<void> {
    await Promise.all(
      this.transports.map(transport => 
        transport.close ? transport.close() : Promise.resolve()
      )
    );
  }
}