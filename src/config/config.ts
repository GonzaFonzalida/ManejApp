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
