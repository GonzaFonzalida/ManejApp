import { Request, Response, NextFunction } from 'express';
import { body, param, query, validationResult } from 'express-validator';
import { ZodSchema } from 'zod';

// Enhanced Zod validation middleware
export const validateZodSchema = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      // Validate only the body, not the entire request object
      const result = schema.parse(req.body);
      req.body = result;
      next();
    } catch (error: any) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: JSON.stringify(error.errors || error.message),
      });
    }
  };
};

// Express-validator middleware for common validations
export const handleValidationErrors = (req: Request, res: Response, next: NextFunction) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      error: 'Validation failed',
      details: errors.array(),
    });
  }
  next();
};

// Common validation rules
export const emailValidation = () => body('email').isEmail().normalizeEmail();
export const passwordValidation = () => body('password').isLength({ min: 8 }).matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/);
export const dniValidation = () => body('dni').isLength({ min: 7, max: 8 }).isNumeric();
export const idParamValidation = () => param('id').isInt({ min: 1 });

// Sanitization middleware
export const sanitizeInput = (req: Request, res: Response, next: NextFunction) => {
  const sanitizeObject = (obj: any): any => {
    if (typeof obj === 'string') {
      return obj.trim().replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
    }
    if (typeof obj === 'object' && obj !== null) {
      const sanitized: any = {};
      for (const key in obj) {
        sanitized[key] = sanitizeObject(obj[key]);
      }
      return sanitized;
    }
    return obj;
  };

  // Check for malicious content in query and params (read-only properties)
  const checkForMalicious = (obj: any): boolean => {
    if (typeof obj === 'string') {
      return /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi.test(obj);
    }
    if (typeof obj === 'object' && obj !== null) {
      return Object.values(obj).some(checkForMalicious);
    }
    return false;
  };

  if (checkForMalicious(req.query) || checkForMalicious(req.params)) {
    return res.status(400).json({
      success: false,
      error: 'Potentially malicious content detected in URL parameters',
      timestamp: new Date().toISOString()
    });
  }

  // Only sanitize the mutable body
  req.body = sanitizeObject(req.body);

  next();
};