#!/usr/bin/env bash
# Inicia el frontend Flutter en Chrome.
# Usa puerto 7357 para que Google Sign-In funcione (agregar http://localhost:7357 en Google Cloud).
# Uso: ./scripts/start-frontend.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$(dirname "$SCRIPT_DIR")/ManejApp-frontend"

if [ ! -d "$FRONTEND_DIR" ]; then
  echo "Error: No existe $FRONTEND_DIR"
  echo "Ejecutá primero: ./scripts/setup-frontend-for-testing.sh"
  exit 1
fi

cd "$FRONTEND_DIR"
echo "==> Iniciando app Flutter en Chrome (puerto 7357 para Google Sign-In)..."
echo "==> Mantené esta terminal abierta. Ctrl+C para detener."
echo ""
exec flutter run -d chrome --web-hostname=localhost --web-port=7357
