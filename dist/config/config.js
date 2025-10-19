"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getMercadoPagoUrl = exports.LOG_RETENTION_DAYS = exports.LOG_TABLE_NAME = exports.LOG_MAX_FILES = exports.LOG_MAX_SIZE = exports.LOG_FILENAME = exports.LOG_DIRECTORY = exports.ENABLE_DATABASE_LOGS = exports.ENABLE_FILE_LOGS = exports.ENABLE_CONSOLE_LOGS = exports.LOG_LEVEL = exports.APP_URL_PUBLIC = exports.APP_URL = exports.MERCADOPAGO_PUBLIC_KEY = exports.MERCADOPAGO_ACCESS_TOKEN = exports.COOKIE_SECRET = exports.JWT_REFRESH_EXPIRATION = exports.JWT_EXPIRATION = exports.JWT_REFRESH_SECRET = exports.JWT_SECRET = exports.DATABASE_URL = exports.PORT = exports.NODE_ENV = void 0;
const zod_1 = require("zod");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
// Definimos el esquema de validación para las variables de entorno
const envSchema = zod_1.z.object({
    NODE_ENV: zod_1.z.enum(["development", "production", "test"]).default("development"),
    PORT: zod_1.z.string().default("3000"),
    DATABASE_URL: zod_1.z.string().url(),
    JWT_SECRET: zod_1.z.string().min(10, "JWT_SECRET debe tener al menos 10 caracteres"),
    JWT_REFRESH_SECRET: zod_1.z.string().min(10, "JWT_REFRESH_SECRET debe tener al menos 10 caracteres"),
    JWT_EXPIRATION: zod_1.z.string().default("15m"), // acceso
    JWT_REFRESH_EXPIRATION: zod_1.z.string().default("7d"), // refresh token
    COOKIE_SECRET: zod_1.z.string().min(10, "COOKIE_SECRET debe tener al menos 10 caracteres"),
    // Mercado Pago configuration
    MERCADOPAGO_ACCESS_TOKEN: zod_1.z.string().min(1, "MERCADOPAGO_ACCESS_TOKEN es requerido"),
    MERCADOPAGO_PUBLIC_KEY: zod_1.z.string().min(1, "MERCADOPAGO_PUBLIC_KEY es requerido"),
    APP_URL: zod_1.z.string().url().optional().default("http://localhost:3000"),
    APP_URL_PUBLIC: zod_1.z.string().url().optional(),
    // Logging configuration
    LOG_LEVEL: zod_1.z.enum(["error", "warn", "info", "debug"]).default("info"),
    ENABLE_CONSOLE_LOGS: zod_1.z.string().default("true").transform(val => val === "true"),
    ENABLE_FILE_LOGS: zod_1.z.string().default("true").transform(val => val === "true"),
    ENABLE_DATABASE_LOGS: zod_1.z.string().default("false").transform(val => val === "true"),
    // File logging configuration
    LOG_DIRECTORY: zod_1.z.string().default("./logs"),
    LOG_FILENAME: zod_1.z.string().default("app.log"),
    LOG_MAX_SIZE: zod_1.z.string().default("50MB"),
    LOG_MAX_FILES: zod_1.z.string().default("10").transform(val => parseInt(val, 10)),
    // Database logging configuration
    LOG_TABLE_NAME: zod_1.z.string().default("logs"),
    LOG_RETENTION_DAYS: zod_1.z.string().default("30").transform(val => parseInt(val, 10)),
});
// Parseamos y validamos process.env
const env = envSchema.parse(process.env);
// Exportamos constantes tipadas y listas para usar
exports.NODE_ENV = env.NODE_ENV;
exports.PORT = parseInt(env.PORT, 10);
exports.DATABASE_URL = env.DATABASE_URL;
exports.JWT_SECRET = env.JWT_SECRET;
exports.JWT_REFRESH_SECRET = env.JWT_REFRESH_SECRET;
exports.JWT_EXPIRATION = env.JWT_EXPIRATION;
exports.JWT_REFRESH_EXPIRATION = env.JWT_REFRESH_EXPIRATION;
exports.COOKIE_SECRET = env.COOKIE_SECRET;
// Mercado Pago configuration
exports.MERCADOPAGO_ACCESS_TOKEN = env.MERCADOPAGO_ACCESS_TOKEN;
exports.MERCADOPAGO_PUBLIC_KEY = env.MERCADOPAGO_PUBLIC_KEY;
exports.APP_URL = env.APP_URL;
exports.APP_URL_PUBLIC = env.APP_URL_PUBLIC;
// Logging configuration exports
exports.LOG_LEVEL = env.LOG_LEVEL;
exports.ENABLE_CONSOLE_LOGS = env.ENABLE_CONSOLE_LOGS;
exports.ENABLE_FILE_LOGS = env.ENABLE_FILE_LOGS;
exports.ENABLE_DATABASE_LOGS = env.ENABLE_DATABASE_LOGS;
exports.LOG_DIRECTORY = env.LOG_DIRECTORY;
exports.LOG_FILENAME = env.LOG_FILENAME;
exports.LOG_MAX_SIZE = env.LOG_MAX_SIZE;
exports.LOG_MAX_FILES = env.LOG_MAX_FILES;
exports.LOG_TABLE_NAME = env.LOG_TABLE_NAME;
exports.LOG_RETENTION_DAYS = env.LOG_RETENTION_DAYS;
// Helper function to get the appropriate URL for Mercado Pago
const getMercadoPagoUrl = () => {
    // In development, prefer public URL if available (for ngrok, etc.)
    if (exports.NODE_ENV === 'development' && exports.APP_URL_PUBLIC) {
        return exports.APP_URL_PUBLIC;
    }
    // In production or when no public URL is set, use APP_URL
    return exports.APP_URL;
};
exports.getMercadoPagoUrl = getMercadoPagoUrl;
