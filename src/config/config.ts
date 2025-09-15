import { z } from "zod";
import dotenv from "dotenv";

dotenv.config();

// Definimos el esquema de validación para las variables de entorno
const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.string().default("3000"),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(10, "JWT_SECRET debe tener al menos 10 caracteres"),
  JWT_REFRESH_SECRET: z.string().min(10, "JWT_REFRESH_SECRET debe tener al menos 10 caracteres"),
  JWT_EXPIRATION: z.string().default("15m"), // acceso
  JWT_REFRESH_EXPIRATION: z.string().default("7d"), // refresh token
  COOKIE_SECRET: z.string().min(10, "COOKIE_SECRET debe tener al menos 10 caracteres"),

  // Mercado Pago configuration
  MERCADOPAGO_ACCESS_TOKEN: z.string().min(1, "MERCADOPAGO_ACCESS_TOKEN es requerido"),
  MERCADOPAGO_PUBLIC_KEY: z.string().min(1, "MERCADOPAGO_PUBLIC_KEY es requerido"),
  APP_URL: z.string().url().optional().default("http://localhost:3000"),
  APP_URL_PUBLIC: z.string().url().optional(),

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
});

// Parseamos y validamos process.env
const env = envSchema.parse(process.env);

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
export const APP_URL = env.APP_URL;
export const APP_URL_PUBLIC = env.APP_URL_PUBLIC;

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

// Helper function to get the appropriate URL for Mercado Pago
export const getMercadoPagoUrl = (): string => {
  // In development, prefer public URL if available (for ngrok, etc.)
  if (NODE_ENV === 'development' && APP_URL_PUBLIC) {
    return APP_URL_PUBLIC;
  }
  // In production or when no public URL is set, use APP_URL
  return APP_URL;
};
