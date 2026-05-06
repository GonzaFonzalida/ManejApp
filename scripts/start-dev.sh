#!/usr/bin/env bash
# Script robusto para desarrollo: inicia el backend y espera a que esté listo.
# Uso: ./scripts/start-dev.sh
# Dejá esta terminal abierta mientras usás la app. El backend se reinicia solo si crashea.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

# Liberar puertos del API local (3000 legado + 3099 actual)
if [ -x "$SCRIPT_DIR/kill-backend-ports.sh" ]; then
  bash "$SCRIPT_DIR/kill-backend-ports.sh"
else
  for port in 3000 3099; do
    if lsof -ti:$port >/dev/null 2>&1; then
      echo "==> Liberando puerto $port..."
      lsof -ti:$port | xargs kill -9 2>/dev/null || true
    fi
  done
fi
sleep 1

echo "==> Iniciando backend (PORT desde .env; por defecto en código: 3099)..."
echo "==> (Mantené esta terminal abierta. Ctrl+C para detener)"
echo ""

# Iniciar en primer plano para que el usuario vea los logs
if command -v pnpm >/dev/null 2>&1; then
  exec pnpm run dev
else
  exec npm run dev
fi
