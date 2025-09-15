import fs from 'fs/promises';
import path from 'path';
import { LogTransport, LogEntry } from '../LogEntry';

export interface FileTransportConfig {
  directory: string;
  filename: string;
  maxSize: string; // e.g., '10MB'
  maxFiles: number;
}

export class FileTransport implements LogTransport {
  private config: FileTransportConfig;
  private currentFilePath: string;

  constructor(config: FileTransportConfig) {
    this.config = config;
    this.currentFilePath = path.join(config.directory, config.filename);
    this.ensureDirectoryExists();
  }

  async log(entry: LogEntry): Promise<void> {
    try {
      // Check if rotation is needed
      await this.rotateIfNeeded();

      // Format log entry as JSON
      const logLine = JSON.stringify({
        timestamp: entry.timestamp.toISOString(),
        level: entry.level,
        message: entry.message,
        context: entry.context,
        error: entry.error,
        metadata: entry.metadata,
      }) + '\n';

      // Append to file
      await fs.appendFile(this.currentFilePath, logLine, 'utf8');
    } catch (error) {
      console.error('FileTransport error:', error);
    }
  }

  private async ensureDirectoryExists(): Promise<void> {
    try {
      await fs.mkdir(this.config.directory, { recursive: true });
    } catch (error) {
      console.error('Failed to create log directory:', error);
    }
  }

  private async rotateIfNeeded(): Promise<void> {
    try {
      const stats = await fs.stat(this.currentFilePath);
      const maxSizeBytes = this.parseSize(this.config.maxSize);

      if (stats.size >= maxSizeBytes) {
        await this.rotateFiles();
      }
    } catch (error) {
      // File doesn't exist yet, no rotation needed
      if ((error as any).code !== 'ENOENT') {
        console.error('Error checking file size:', error);
      }
    }
  }

  private async rotateFiles(): Promise<void> {
    try {
      const { dir, name, ext } = path.parse(this.currentFilePath);

      // Shift existing files
      for (let i = this.config.maxFiles - 1; i > 0; i--) {
        const oldFile = path.join(dir, `${name}.${i}${ext}`);
        const newFile = path.join(dir, `${name}.${i + 1}${ext}`);

        try {
          await fs.rename(oldFile, newFile);
        } catch (error) {
          // File doesn't exist, continue
          if ((error as any).code !== 'ENOENT') {
            console.error(`Error rotating ${oldFile}:`, error);
          }
        }
      }

      // Move current file to .1
      const rotatedFile = path.join(dir, `${name}.1${ext}`);
      try {
        await fs.rename(this.currentFilePath, rotatedFile);
      } catch (error) {
        console.error('Error rotating current file:', error);
      }

      // Remove oldest file if it exceeds maxFiles
      const oldestFile = path.join(dir, `${name}.${this.config.maxFiles + 1}${ext}`);
      try {
        await fs.unlink(oldestFile);
      } catch (error) {
        // File doesn't exist, that's fine
        if ((error as any).code !== 'ENOENT') {
          console.error('Error removing oldest file:', error);
        }
      }
    } catch (error) {
      console.error('Error during file rotation:', error);
    }
  }

  private parseSize(sizeStr: string): number {
    const units: Record<string, number> = {
      'B': 1,
      'KB': 1024,
      'MB': 1024 * 1024,
      'GB': 1024 * 1024 * 1024,
    };

    const match = sizeStr.match(/^(\d+(?:\.\d+)?)\s*([A-Z]{1,2})$/i);
    if (!match) {
      throw new Error(`Invalid size format: ${sizeStr}`);
    }

    const [, size, unit] = match;
    const multiplier = units[unit.toUpperCase()];
    if (!multiplier) {
      throw new Error(`Unknown size unit: ${unit}`);
    }

    return parseFloat(size) * multiplier;
  }

  async close(): Promise<void> {
    // No cleanup needed for file transport
  }
}