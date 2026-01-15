import multer from 'multer';
import path from 'path';
import { Request } from 'express';
import fs from 'fs';
import CustomizedError from '@shared/classes/CustomizedError';

// Ensure upload directory exists
const uploadDir = path.join(process.cwd(), 'uploads', 'profiles');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// File filter for images only
const fileFilter = (req: Request, file: Express.Multer.File, cb: multer.FileFilterCallback) => {
  const allowedTypes = /jpeg|jpg|png|gif|webp/;
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = allowedTypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb(new CustomizedError('Solo se permiten archivos de imagen (jpeg, jpg, png, gif, webp)', 400));
  }
};

// Storage configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Generate unique filename with user ID
    const userId = (req as any).user?.id || 'anonymous';
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = path.extname(file.originalname);
    cb(null, `profile-${userId}-${uniqueSuffix}${extension}`);
  }
});

// Upload configuration
export const uploadProfileImage = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
  fileFilter: fileFilter
});

// Single file upload middleware
export const uploadSingleImage = uploadProfileImage.single('profileImage');

// Multiple files upload middleware (if needed in future)
export const uploadMultipleImages = uploadProfileImage.array('images', 5);

// Validate uploaded file
export const validateUploadedFile = (req: Request, res: any, next: any) => {
  if (!req.file) {
    return next(new CustomizedError('No se encontró ningún archivo', 400));
  }

  // Additional validation
  const file = req.file;
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
  const maxSize = 5 * 1024 * 1024; // 5MB

  if (!allowedTypes.includes(file.mimetype)) {
    // Clean up uploaded file
    fs.unlinkSync(file.path);
    return next(new CustomizedError('Tipo de archivo no permitido', 400));
  }

  if (file.size > maxSize) {
    // Clean up uploaded file
    fs.unlinkSync(file.path);
    return next(new CustomizedError('El archivo es demasiado grande (máximo 5MB)', 400));
  }

  next();
};