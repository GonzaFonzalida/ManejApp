# Usar imagen oficial de Node.js LTS
FROM node:20-alpine AS base

# Instalar dependencias del sistema necesarias para Prisma
RUN apk add --no-cache openssl

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración de dependencias
COPY package*.json pnpm-lock.yaml ./

# Instalar pnpm globalmente
RUN npm install -g pnpm

# Etapa de dependencias
FROM base AS deps
RUN pnpm install --frozen-lockfile

# Etapa de construcción
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Generar cliente de Prisma
RUN npx prisma generate

# Etapa de producción
FROM base AS runner

# Crear usuario no-root para seguridad
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copiar archivos necesarios
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma
COPY dist ./dist
COPY start.sh ./start.sh

# Crear directorio de logs y asignar permisos
RUN mkdir -p logs && chown -R nextjs:nodejs logs

# Hacer ejecutable el script de inicio
RUN chmod +x start.sh

# Cambiar al usuario no-root
USER nextjs

# Exponer puerto
EXPOSE 3000

# Variables de entorno por defecto
ENV NODE_ENV=production
ENV PORT=3000

# Comando de inicio
CMD ["./start.sh"]