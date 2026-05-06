#!/usr/bin/env bash
# Inicia el backend para testeo local.
# Uso: ./scripts/start-backend.sh
# Dejá esta terminal abierta mientras probás la app.

set -e
cd "$(dirname "$0")/.."
echo "==> Iniciando backend (PORT en .env; por defecto 3099)..."
npm run dev
