import { LogTransport, LogEntry } from '../LogEntry';
import { prisma } from '@config/prismaClient';

export interface DatabaseTransportConfig {
  tableName: string;
  retentionDays: number;
}

export class DatabaseTransport implements LogTransport {
  private config: DatabaseTransportConfig;
  private cleanupInterval: NodeJS.Timeout | null = null;

  constructor(config: DatabaseTransportConfig) {
    this.config = config;
    this.startCleanupSchedule();
  }

  async log(entry: LogEntry): Promise<void> {
    try {
      // Store log in database using raw SQL to avoid Prisma schema dependency
      await prisma.$executeRaw`
        INSERT INTO logs (
          timestamp, 
          level, 
          message, 
          context, 
          error, 
          metadata,
          created_at
        ) VALUES (
          ${entry.timestamp},
          ${entry.level},
          ${entry.message},
          ${entry.context ? JSON.stringify(entry.context) : null},
          ${entry.error ? JSON.stringify(entry.error) : null},
          ${entry.metadata ? JSON.stringify(entry.metadata) : null},
          NOW()
        )
      `;
    } catch (error) {
      // Fallback to console if database fails
      console.error('DatabaseTransport error:', error);
      console.log('Failed log entry:', JSON.stringify(entry, null, 2));
    }
  }

  private startCleanupSchedule(): void {
    // Run cleanup every 24 hours
    this.cleanupInterval = setInterval(() => {
      this.cleanupOldLogs().catch(error => {
        console.error('Log cleanup error:', error);
      });
    }, 24 * 60 * 60 * 1000);

    // Run initial cleanup
    this.cleanupOldLogs().catch(error => {
      console.error('Initial log cleanup error:', error);
    });
  }

  private async cleanupOldLogs(): Promise<void> {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - this.config.retentionDays);

      await prisma.$executeRaw`
        DELETE FROM logs 
        WHERE created_at < ${cutoffDate}
      `;

      console.log(`Cleaned up logs older than ${this.config.retentionDays} days`);
    } catch (error) {
      console.error('Error cleaning up old logs:', error);
    }
  }

  async close(): Promise<void> {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
  }
}

// SQL to create the logs table (run this migration manually or add to Prisma schema)
export const createLogsTableSQL = `
CREATE TABLE IF NOT EXISTS logs (
  id SERIAL PRIMARY KEY,
  timestamp TIMESTAMP NOT NULL,
  level VARCHAR(10) NOT NULL,
  message TEXT NOT NULL,
  context JSONB,
  error JSONB,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  
  -- Indexes for better query performance
  INDEX idx_logs_timestamp (timestamp),
  INDEX idx_logs_level (level),
  INDEX idx_logs_created_at (created_at),
  INDEX idx_logs_context_request_id ((context->>'requestId')),
  INDEX idx_logs_context_user_id ((context->>'userId'))
);
`;