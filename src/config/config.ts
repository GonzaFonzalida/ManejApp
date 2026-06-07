import { z } from "zod";
import dotenv from "dotenv";

dotenv.config();

// Definimos el esquema de validación para las variables de entorno
const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.string().default("3099"),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(10, "JWT_SECRET debe tener al menos 10 caracteres"),
  JWT_REFRESH_SECRET: z.string().min(10, "JWT_REFRESH_SECRET debe tener al menos 10 caracteres"),
  JWT_EXPIRATION: z.string().default("15m"), // acceso
  JWT_REFRESH_EXPIRATION: z.string().default("7d"), // refresh token
  COOKIE_SECRET: z.string().min(10, "COOKIE_SECRET debe tener al menos 10 caracteres"),

  // Mercado Pago configuration
  MERCADOPAGO_ACCESS_TOKEN: z.string().min(1, "MERCADOPAGO_ACCESS_TOKEN es requerido"),
  MERCADOPAGO_PUBLIC_KEY: z.string().min(1, "MERCADOPAGO_PUBLIC_KEY es requerido"),
  /** OAuth marketplace: ID de la aplicación (Tus integraciones → Credenciales). */
  MERCADOPAGO_CLIENT_ID: z
    .string()
    .optional()
    .transform((s) => (s && s.trim().length > 0 ? s.trim() : undefined)),
  MERCADOPAGO_CLIENT_SECRET: z
    .string()
    .optional()
    .transform((s) => (s && s.trim().length > 0 ? s.trim() : undefined)),
  /** Alias opcional de client_id si en MP figura como App ID. */
  MERCADOPAGO_APP_ID: z
    .string()
    .optional()
    .transform((s) => (s && s.trim().length > 0 ? s.trim() : undefined)),
  /** Redirect URI estática registrada en Mercado Pago (debe coincidir exactamente). */
  MERCADOPAGO_REDIRECT_URI: z
    .string()
    .url()
    .optional()
    .transform((s) => (s && s.trim().length > 0 ? s.trim() : undefined)),
  /** Secreto de firma de webhooks (Tus integraciones → Webhooks). Obligatorio en producción. */
  MERCADOPAGO_WEBHOOK_SECRET: z.string().optional().transform((s) => (s && s.trim().length > 0 ? s.trim() : undefined)),
  /** Porcentaje que retiene la app sobre el bruto (ej. 20 → el instructor recibe ~80%). */
  APP_COMMISSION_PERCENTAGE: z
    .string()
    .default("20")
    .transform((v) => {
      const n = parseFloat(v);
      if (Number.isNaN(n) || n < 0 || n > 100) {
        throw new Error("APP_COMMISSION_PERCENTAGE debe ser un número entre 0 y 100");
      }
      return n;
    }),
  APP_URL: z.string().url().optional().default("http://localhost:3099"),
  APP_URL_PUBLIC: z.string().url().optional(),

  GOOGLE_CLIENT_ID: z.string().optional().transform(s => (s && s.trim().length > 0 ? s.trim() : undefined)),

  /** Bundle ID de la app iOS (Sign in with Apple). Debe coincidir con el `aud` del identityToken. */
  APPLE_CLIENT_ID: z.string().optional().transform(s => (s && s.trim().length > 0 ? s.trim() : undefined)),

  // Logging configuration
  LOG_LEVEL: z.enum(["error", "warn", "info", "debug"]).default("info"),
  ENABLE_CONSOLE_LOGS: z.string().default("true").transform(val => val === "true"),
  ENABLE_FILE_LOGS: z.string().default("true").transform(val => val === "true"),
  ENABLE_DATABASE_LOGS: z.string().default("false").transform(val => val === "true"),
  
  // File logging configuration
  LOG_DIRECTORY: z.string().default("./logs"),
  LOG_FILENAME: z.string().default("app.log"),
  LOG_MAX_SIZE: z.string().default("50MB"),
  LOG_MAX_FILES: z.string().default("10").transform(val => parseInt(val, 10)),
  
  // Database logging configuration
  LOG_TABLE_NAME: z.string().default("logs"),
  LOG_RETENTION_DAYS: z.string().default("30").transform(val => parseInt(val, 10)),
  
  // Security configuration
  RATE_LIMIT_WINDOW_MS: z.string().default("900000").transform(val => parseInt(val, 10)), // 15 minutes
  RATE_LIMIT_MAX_REQUESTS: z.string().default("100").transform(val => parseInt(val, 10)),
  AUTH_RATE_LIMIT_MAX: z.string().default("5").transform(val => parseInt(val, 10)),
});

// Parseamos y validamos process.env
const env = envSchema.superRefine((data, ctx) => {
  if (data.NODE_ENV === "production") {
    if (!data.MERCADOPAGO_WEBHOOK_SECRET || data.MERCADOPAGO_WEBHOOK_SECRET.length < 8) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message:
          "MERCADOPAGO_WEBHOOK_SECRET es obligatorio en producción (clave de firma de webhooks en Mercado Pago).",
        path: ["MERCADOPAGO_WEBHOOK_SECRET"],
      });
    }
  }
}).parse(process.env);

// Exportamos constantes tipadas y listas para usar
export const NODE_ENV = env.NODE_ENV;
export const PORT = parseInt(env.PORT, 10);
export const DATABASE_URL = env.DATABASE_URL;

export const JWT_SECRET = env.JWT_SECRET;
export const JWT_REFRESH_SECRET = env.JWT_REFRESH_SECRET;
export const JWT_EXPIRATION = env.JWT_EXPIRATION;
export const JWT_REFRESH_EXPIRATION = env.JWT_REFRESH_EXPIRATION;

export const COOKIE_SECRET = env.COOKIE_SECRET;

// Mercado Pago configuration
export const MERCADOPAGO_ACCESS_TOKEN = env.MERCADOPAGO_ACCESS_TOKEN;
export const MERCADOPAGO_PUBLIC_KEY = env.MERCADOPAGO_PUBLIC_KEY;
export const MERCADOPAGO_CLIENT_ID = env.MERCADOPAGO_CLIENT_ID;
export const MERCADOPAGO_CLIENT_SECRET = env.MERCADOPAGO_CLIENT_SECRET;
export const MERCADOPAGO_APP_ID = env.MERCADOPAGO_APP_ID;
export const MERCADOPAGO_REDIRECT_URI = env.MERCADOPAGO_REDIRECT_URI;
export const MERCADOPAGO_WEBHOOK_SECRET = env.MERCADOPAGO_WEBHOOK_SECRET;
export const APP_COMMISSION_PERCENTAGE = env.APP_COMMISSION_PERCENTAGE;
export const APP_URL = env.APP_URL;
export const APP_URL_PUBLIC = env.APP_URL_PUBLIC;
export const GOOGLE_CLIENT_ID = env.GOOGLE_CLIENT_ID;
export const APPLE_CLIENT_ID = env.APPLE_CLIENT_ID;

// Logging configuration exports
export const LOG_LEVEL = env.LOG_LEVEL;
export const ENABLE_CONSOLE_LOGS = env.ENABLE_CONSOLE_LOGS;
export const ENABLE_FILE_LOGS = env.ENABLE_FILE_LOGS;
export const ENABLE_DATABASE_LOGS = env.ENABLE_DATABASE_LOGS;
export const LOG_DIRECTORY = env.LOG_DIRECTORY;
export const LOG_FILENAME = env.LOG_FILENAME;
export const LOG_MAX_SIZE = env.LOG_MAX_SIZE;
export const LOG_MAX_FILES = env.LOG_MAX_FILES;
export const LOG_TABLE_NAME = env.LOG_TABLE_NAME;
export const LOG_RETENTION_DAYS = env.LOG_RETENTION_DAYS;

// Security configuration exports
export const RATE_LIMIT_WINDOW_MS = env.RATE_LIMIT_WINDOW_MS;
export const RATE_LIMIT_MAX_REQUESTS = env.RATE_LIMIT_MAX_REQUESTS;
export const AUTH_RATE_LIMIT_MAX = env.AUTH_RATE_LIMIT_MAX;

/** Quita slash final para evitar URLs rotas tipo https://host//path. */
export const normalizeBaseUrl = (url: string): string => {
  const trimmed = url.trim();
  if (!trimmed) {
    throw new Error("URL base vacía");
  }
  return trimmed.replace(/\/+$/, "");
};

// Helper function to get the appropriate URL for Mercado Pago
export const getMercadoPagoUrl = (): string => {
  // In development, prefer public URL if available (for ngrok, etc.)
  if (NODE_ENV === "development" && APP_URL_PUBLIC) {
    return normalizeBaseUrl(APP_URL_PUBLIC);
  }
  // In production or when no public URL is set, use APP_URL
  return normalizeBaseUrl(APP_URL);
};

/** Client ID efectivo para OAuth (CLIENT_ID o APP_ID). */
export const getMercadoPagoOAuthClientId = (): string | undefined =>
  MERCADOPAGO_CLIENT_ID ?? MERCADOPAGO_APP_ID;

/** Redirect URI OAuth: env explícita o derivada de la URL pública del API. */
export const getMercadoPagoOAuthRedirectUri = (): string => {
  if (MERCADOPAGO_REDIRECT_URI) return MERCADOPAGO_REDIRECT_URI;
  return `${getMercadoPagoUrl()}/api/v1/instructors/mercadopago/callback`;
};
