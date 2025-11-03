#!/bin/bash

# Script de inicio para el contenedor de ManejApp

echo "🚀 Iniciando ManejApp Backend..."

# Esperar a que la base de datos esté disponible
echo "⏳ Esperando conexión a la base de datos..."
npx prisma db push --accept-data-loss

# Ejecutar migraciones de Prisma
echo "🔄 Ejecutando migraciones de base de datos..."
npx prisma migrate deploy

# Generar cliente de Prisma (por si acaso)
echo "🔧 Generando cliente de Prisma..."
npx prisma generate

# Iniciar la aplicación
echo "✅ Iniciando servidor..."
# Verificar si existe dist/index.js, si no usar src/index.ts con ts-node
if [ -f "dist/index.js" ]; then
    exec node dist/index.js
else
    exec npx ts-node -r tsconfig-paths/register src/index.ts
fi