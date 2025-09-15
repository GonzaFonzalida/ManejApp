export enum LogLevel {
  ERROR = 'error',
  WARN = 'warn',
  INFO = 'info',
  DEBUG = 'debug'
}

export interface LogContext {
  requestId?: string;
  userId?: number;
  userRole?: string;
  ip?: string;
  userAgent?: string;
  method?: string;
  url?: string;
  statusCode?: number;
  responseTime?: number;
  module?: string;
  function?: string;
  [key: string]: any;
}

export interface LogEntry {
  timestamp: Date;
  level: LogLevel;
  message: string;
  context?: LogContext;
  error?: {
    name: string;
    message: string;
    stack?: string;
    code?: string | number;
  };
  metadata?: Record<string, any>;
}

export interface LogTransport {
  log(entry: LogEntry): Promise<void>;
  close?(): Promise<void>;
}

export interface LoggerConfig {
  level: LogLevel;
  transports: LogTransport[];
  enableConsole: boolean;
  enableFile: boolean;
  enableDatabase: boolean;
  fileConfig?: {
    directory: string;
    filename: string;
    maxSize: string;
    maxFiles: number;
  };
  databaseConfig?: {
    tableName: string;
    retentionDays: number;
  };
}