"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FileTransport = void 0;
const promises_1 = __importDefault(require("fs/promises"));
const path_1 = __importDefault(require("path"));
class FileTransport {
    config;
    currentFilePath;
    constructor(config) {
        this.config = config;
        this.currentFilePath = path_1.default.join(config.directory, config.filename);
        this.ensureDirectoryExists();
    }
    async log(entry) {
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
            await promises_1.default.appendFile(this.currentFilePath, logLine, 'utf8');
        }
        catch (error) {
            console.error('FileTransport error:', error);
        }
    }
    async ensureDirectoryExists() {
        try {
            await promises_1.default.mkdir(this.config.directory, { recursive: true });
        }
        catch (error) {
            console.error('Failed to create log directory:', error);
        }
    }
    async rotateIfNeeded() {
        try {
            const stats = await promises_1.default.stat(this.currentFilePath);
            const maxSizeBytes = this.parseSize(this.config.maxSize);
            if (stats.size >= maxSizeBytes) {
                await this.rotateFiles();
            }
        }
        catch (error) {
            // File doesn't exist yet, no rotation needed
            if (error.code !== 'ENOENT') {
                console.error('Error checking file size:', error);
            }
        }
    }
    async rotateFiles() {
        try {
            const { dir, name, ext } = path_1.default.parse(this.currentFilePath);
            // Shift existing files
            for (let i = this.config.maxFiles - 1; i > 0; i--) {
                const oldFile = path_1.default.join(dir, `${name}.${i}${ext}`);
                const newFile = path_1.default.join(dir, `${name}.${i + 1}${ext}`);
                try {
                    await promises_1.default.rename(oldFile, newFile);
                }
                catch (error) {
                    // File doesn't exist, continue
                    if (error.code !== 'ENOENT') {
                        console.error(`Error rotating ${oldFile}:`, error);
                    }
                }
            }
            // Move current file to .1
            const rotatedFile = path_1.default.join(dir, `${name}.1${ext}`);
            try {
                await promises_1.default.rename(this.currentFilePath, rotatedFile);
            }
            catch (error) {
                console.error('Error rotating current file:', error);
            }
            // Remove oldest file if it exceeds maxFiles
            const oldestFile = path_1.default.join(dir, `${name}.${this.config.maxFiles + 1}${ext}`);
            try {
                await promises_1.default.unlink(oldestFile);
            }
            catch (error) {
                // File doesn't exist, that's fine
                if (error.code !== 'ENOENT') {
                    console.error('Error removing oldest file:', error);
                }
            }
        }
        catch (error) {
            console.error('Error during file rotation:', error);
        }
    }
    parseSize(sizeStr) {
        const units = {
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
    async close() {
        // No cleanup needed for file transport
    }
}
exports.FileTransport = FileTransport;
