import fs from 'fs';
import path from 'path';
import { promisify } from 'util';
import CustomizedError from '@shared/classes/CustomizedError';

const unlinkAsync = promisify(fs.unlink);

export default class FileService {
  private static uploadDir = path.join(process.cwd(), 'uploads', 'profiles');

  /**
   * Delete a file if it exists
   */
  static async deleteFile(filePath: string): Promise<void> {
    try {
      const fullPath = path.join(this.uploadDir, filePath);
      if (fs.existsSync(fullPath)) {
        await unlinkAsync(fullPath);
      }
    } catch (error) {
      console.error('Error deleting file:', error);
      // Don't throw error for cleanup operations
    }
  }

  /**
   * Get file stats
   */
  static async getFileStats(filePath: string): Promise<fs.Stats | null> {
    try {
      const fullPath = path.join(this.uploadDir, filePath);
      return await promisify(fs.stat)(fullPath);
    } catch (error) {
      return null;
    }
  }

  /**
   * Check if file exists
   */
  static fileExists(filePath: string): boolean {
    try {
      const fullPath = path.join(this.uploadDir, filePath);
      return fs.existsSync(fullPath);
    } catch (error) {
      return false;
    }
  }

  /**
   * Get full file path
   */
  static getFullFilePath(filePath: string): string {
    return path.join(this.uploadDir, filePath);
  }

  /**
   * Validate file extension
   */
  static isValidImageExtension(filename: string): boolean {
    const validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const ext = path.extname(filename).toLowerCase();
    return validExtensions.includes(ext);
  }

  /**
   * Generate unique filename
   */
  static generateUniqueFilename(userId: number, originalFilename: string): string {
    const extension = path.extname(originalFilename);
    const timestamp = Date.now();
    const random = Math.round(Math.random() * 1E9);
    return `profile-${userId}-${timestamp}-${random}${extension}`;
  }

  /**
   * Clean up old profile images for a user
   */
  static async cleanupOldProfileImages(userId: number, currentImagePath?: string): Promise<void> {
    try {
      const files = fs.readdirSync(this.uploadDir);
      const userFiles = files.filter(file =>
        file.startsWith(`profile-${userId}-`) &&
        (!currentImagePath || !file.includes(path.basename(currentImagePath)))
      );

      // Delete old files for this user
      for (const file of userFiles) {
        await this.deleteFile(file);
      }
    } catch (error) {
      console.error('Error cleaning up old profile images:', error);
    }
  }

  /**
   * Ensure upload directory exists
   */
  static ensureUploadDirExists(): void {
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  /**
   * Get file size in human readable format
   */
  static formatFileSize(bytes: number): string {
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    if (bytes === 0) return '0 Bytes';
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  }
}