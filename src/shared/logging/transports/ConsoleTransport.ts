import { LogTransport, LogEntry, LogLevel } from '../LogEntry';

export class ConsoleTransport implements LogTransport {
  private colors = {
    [LogLevel.ERROR]: '\x1b[31m', // Red
    [LogLevel.WARN]: '\x1b[33m',  // Yellow
    [LogLevel.INFO]: '\x1b[36m',  // Cyan
    [LogLevel.DEBUG]: '\x1b[37m', // White
  };

  private reset = '\x1b[0m';

  async log(entry: LogEntry): Promise<void> {
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
      if (entry.error.stack && entry.level === LogLevel.ERROR) {
        logMessage += `\n  Stack: ${entry.error.stack}`;
      }
    }

    // Add metadata
    if (entry.metadata && Object.keys(entry.metadata).length > 0) {
      logMessage += `\n  Metadata: ${JSON.stringify(entry.metadata, null, 2)}`;
    }

    console.log(logMessage);
  }

  private formatContext(context: any): string {
    const parts: string[] = [];
    
    if (context.requestId) parts.push(`reqId=${context.requestId}`);
    if (context.userId) parts.push(`userId=${context.userId}`);
    if (context.method && context.url) parts.push(`${context.method} ${context.url}`);
    if (context.statusCode) parts.push(`status=${context.statusCode}`);
    if (context.responseTime) parts.push(`${context.responseTime}ms`);
    if (context.ip) parts.push(`ip=${context.ip}`);
    if (context.module) parts.push(`module=${context.module}`);
    if (context.function) parts.push(`fn=${context.function}`);

    return parts.join(' | ');
  }
}