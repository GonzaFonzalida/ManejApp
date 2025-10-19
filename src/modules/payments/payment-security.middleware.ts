import { Request, Response, NextFunction } from 'express';
import rateLimit from 'express-rate-limit';
import { AuditService, AuditAction } from '@shared/services/AuditService';

// Rate limiting for payment endpoints
export const paymentRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 payment requests per windowMs
  message: {
    error: 'Too many payment attempts, please try again later.',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Stricter rate limiting for webhook endpoints
export const webhookRateLimit = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100, // Allow more for legitimate webhooks
  message: {
    error: 'Too many webhook requests',
  },
  skip: (req) => {
    // Skip rate limiting for requests with valid webhook signatures
    return req.headers['x-signature'] !== undefined;
  }
});

// Validate payment amounts
export const validatePaymentAmount = (req: Request, res: Response, next: NextFunction) => {
  const { amount } = req.body;
  
  if (!amount || typeof amount !== 'number') {
    return res.status(400).json({
      success: false,
      error: 'Amount is required and must be a number'
    });
  }

  if (amount <= 0) {
    return res.status(400).json({
      success: false,
      error: 'Amount must be greater than 0'
    });
  }

  if (amount > 1000000) { // Max amount: $1,000,000
    return res.status(400).json({
      success: false,
      error: 'Amount exceeds maximum allowed'
    });
  }

  // Round to 2 decimal places
  req.body.amount = Math.round(amount * 100) / 100;
  
  next();
};

// Validate payment method
export const validatePaymentMethod = (req: Request, res: Response, next: NextFunction) => {
  const { paymentMethod } = req.body;
  const allowedMethods = ['cash', 'card', 'transfer', 'mercadopago'];
  
  if (!paymentMethod || !allowedMethods.includes(paymentMethod)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid payment method',
      allowedMethods
    });
  }
  
  next();
};

// Idempotency middleware for payments
export const ensureIdempotency = (req: Request, res: Response, next: NextFunction) => {
  const idempotencyKey = req.headers['idempotency-key'] as string;
  
  if (!idempotencyKey && req.method === 'POST') {
    return res.status(400).json({
      success: false,
      error: 'Idempotency-Key header is required for payment creation'
    });
  }

  // Store idempotency key for processing
  (req as any).idempotencyKey = idempotencyKey;
  
  next();
};

// Audit payment actions
export const auditPaymentAction = (action: AuditAction) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const originalSend = res.json;
    
    res.json = function(data: any) {
      // Log successful payment actions
      if (res.statusCode < 400) {
        AuditService.log({
          action,
          resource: 'payment',
          resourceId: req.params.id || data?.id,
          details: {
            method: req.method,
            path: req.path,
            body: req.body,
            ip: req.ip,
            userAgent: req.get('User-Agent')
          }
        });
      }
      
      return originalSend.call(this, data);
    };
    
    next();
  };
};

// Webhook signature validation
export const validateWebhookSignature = (req: Request, res: Response, next: NextFunction) => {
  const signature = req.headers['x-signature'] as string;
  
  if (!signature) {
    return res.status(401).json({
      success: false,
      error: 'Missing webhook signature'
    });
  }

  // Store signature for service validation
  (req as any).webhookSignature = signature;
  
  next();
};