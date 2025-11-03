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
exec node dist/index.js