import { LogLevel } from './LogEntry';
import { Logger } from './Logger';
import { ConsoleTransport } from './transports/ConsoleTransport';
import { FileTransport } from './transports/FileTransport';
import { DatabaseTransport } from './transports/DatabaseTransport';
import {
  NODE_ENV,
  LOG_LEVEL,
  ENABLE_CONSOLE_LOGS,
  ENABLE_FILE_LOGS,
  ENABLE_DATABASE_LOGS,
  LOG_DIRECTORY,
  LOG_FILENAME,
  LOG_MAX_SIZE,
  LOG_MAX_FILES,
  LOG_TABLE_NAME,
  LOG_RETENTION_DAYS
} from '@config/config';

export class LoggerFactory {
  private static instance: Logger | null = null;

  static createLogger(): Logger {
    if (this.instance) {
      return this.instance;
    }

    const transports = [];

    // Console transport
    if (ENABLE_CONSOLE_LOGS) {
      transports.push(new ConsoleTransport());
    }

    // File transport
    if (ENABLE_FILE_LOGS) {
      transports.push(new FileTransport({
        directory: LOG_DIRECTORY,
        filename: LOG_FILENAME,
        maxSize: LOG_MAX_SIZE,
        maxFiles: LOG_MAX_FILES,
      }));
    }

    // Database transport
    if (ENABLE_DATABASE_LOGS) {
      transports.push(new DatabaseTransport({
        tableName: LOG_TABLE_NAME,
        retentionDays: LOG_RETENTION_DAYS,
      }));
    }

    // Set log level from configuration
    const logLevel = this.parseLogLevel(LOG_LEVEL);

    this.instance = new Logger(transports, logLevel);
    return this.instance;
  }

  private static parseLogLevel(level: string): LogLevel {
    switch (level.toLowerCase()) {
      case 'error':
        return LogLevel.ERROR;
      case 'warn':
        return LogLevel.WARN;
      case 'info':
        return LogLevel.INFO;
      case 'debug':
        return LogLevel.DEBUG;
      default:
        return LogLevel.INFO;
    }
  }

  // Get singleton instance
  static getInstance(): Logger {
    if (!this.instance) {
      this.instance = this.createLogger();
    }
    return this.instance;
  }

  // Reset instance (useful for testing)
  static reset(): void {
    if (this.instance) {
      this.instance.close();
      this.instance = null;
    }
  }
}

// Export singleton instance
export const logger = LoggerFactory.getInstance();

// Export types for external use
export { LogLevel, LogContext, LogEntry } from './LogEntry';
export { Logger } from './Logger';