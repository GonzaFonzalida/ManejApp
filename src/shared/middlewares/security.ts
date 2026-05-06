import rateLimit from 'express-rate-limit';
import cors from 'cors';
import helmet from 'helmet';
import { NODE_ENV } from '@config/config';

// Rate limiting configuration
export const generalRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs
  message: {
    message: 'Demasiadas solicitudes desde esta IP. Probá de nuevo más tarde.',
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
  validate: {
    trustProxy: false, // Disable trust proxy validation
  },
});

// Stricter rate limiting for auth endpoints
export const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs for auth
  message: {
    message: 'Demasiados intentos de inicio de sesión. Esperá unos minutos e intentá de nuevo.',
    error: 'Too many authentication attempts, please try again later.',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
  validate: {
    trustProxy: false, // Disable trust proxy validation
  },
});

/** Origen HTTP típico en desarrollo: localhost o IP privada (LAN) para web/admin desde la red. */
function isAllowedDevOrigin(origin: string): boolean {
  if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin)) return true;
  // RFC1918 + puerto opcional (iPhone / Flutter web en LAN, admin en http://192.168.x.x:3001)
  return /^https?:\/\/(192\.168\.\d{1,3}\.\d{1,3}|10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})(:\d+)?$/i.test(
    origin
  );
}

// CORS configuration
// En desarrollo: localhost + LAN privada; apps nativas suelen no enviar Origin (se permite).
export const corsOptions = {
  origin: NODE_ENV === 'production'
    ? ['https://yourdomain.com'] // Reemplazar con dominios de producción
    : (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      if (!origin) return callback(null, true);
      callback(null, isAllowedDevOrigin(origin));
    },
  credentials: true,
  optionsSuccessStatus: 200,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
};

// Helmet configuration
export const helmetConfig = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      scriptSrc: ["'self'"],
      connectSrc: ["'self'"],
    },
  },
  crossOriginEmbedderPolicy: false, // Disable for Swagger UI
  // Permitir embedding de imágenes/documentos en panel admin (localhost:3001)
  crossOriginResourcePolicy: { policy: "cross-origin" },
});