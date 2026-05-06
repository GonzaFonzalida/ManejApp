#!/usr/bin/env bash
# Levanta el backend de ManejApp accesible desde la red local (iPhone, otro dispositivo en la misma WiFi).
# Uso: desde la carpeta ManejApp/ →  ./scripts/start-demo-backend.sh
#      o: pnpm run dev:demo
#
# Requiere: .env válido (DATABASE_URL, JWT_*, etc.). No hardcodea IP: la detecta en cada ejecución.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PORT="${PORT:-3099}"
export PORT

detect_lan_ip() {
  local iface ip
  iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}' || true)"
  if [[ -n "${iface}" ]]; then
    ip="$(ipconfig getifaddr "${iface}" 2>/dev/null || true)"
    [[ -n "${ip}" ]] && { echo "${ip}"; return; }
  fi
  for iface in en0 en1 en2 en3; do
    ip="$(ipconfig getifaddr "${iface}" 2>/dev/null || true)"
    [[ -n "${ip}" ]] && { echo "${ip}"; return; }
  done
  echo ""
}

LAN_IP="$(detect_lan_ip)"
if [[ -z "${LAN_IP}" ]]; then
  echo "ERROR: No se detectó IP LAN (WiFi/Ethernet). Conectate a la red y reintentá." >&2
  exit 1
fi

BASE_URL="http://${LAN_IP}:${PORT}"
CONFIG_URL="${BASE_URL}/api/v1/config"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ManejApp — backend para demo en LAN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Listen: 0.0.0.0:${PORT} (ver src/index.ts)"
echo ""
echo "  Backend LAN URL:     ${BASE_URL}"
echo "  Endpoint de prueba:  ${CONFIG_URL}"
echo ""
echo "  iPhone / Flutter (misma carpeta que este repo, proyecto frontend):"
echo "    cd ../ManejApp-frontend"
echo "    flutter run --dart-define=API_URL=${BASE_URL} -d <id_dispositivo>"
echo ""
echo "  O usá el helper:     ../ManejApp-frontend/scripts/run-ios-demo.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if command -v curl >/dev/null 2>&1; then
  if curl -sf --max-time 1 "http://127.0.0.1:${PORT}/api/v1/config" >/dev/null 2>&1; then
    echo "AVISO: El puerto ${PORT} ya responde en localhost. Si es otra app, cambiá PORT=3001 ./scripts/start-demo-backend.sh" >&2
  fi
else
  echo "AVISO: curl no encontrado; se omite comprobación previa al arranque." >&2
fi

echo "Arrancando pnpm run dev (Ctrl+C para detener)..."
echo ""

cleanup() { :; }
trap cleanup EXIT

# Arranque en segundo plano para poder hacer curl de verificación
pnpm run dev &
DEV_PID=$!

# Esperar a que el servidor responda
ok=0
for _ in $(seq 1 45); do
  if curl -sf --max-time 2 "http://127.0.0.1:${PORT}/api/v1/config" >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 1
done

if [[ "${ok}" -ne 1 ]]; then
  echo "ERROR: El backend no respondió en http://127.0.0.1:${PORT}/api/v1/config tras ~45s." >&2
  kill "${DEV_PID}" 2>/dev/null || true
  wait "${DEV_PID}" 2>/dev/null || true
  exit 1
fi

echo "✓ curl localhost OK: http://127.0.0.1:${PORT}/api/v1/config"

if curl -sf --max-time 3 "${CONFIG_URL}" >/dev/null 2>&1; then
  echo "✓ curl LAN OK:      ${CONFIG_URL}"
else
  echo "⚠ curl LAN falló:  ${CONFIG_URL}" >&2
  echo "  (Firewall de macOS: Preferencias del Sistema → Red → Firewall; o probá desde el iPhone en Safari)" >&2
fi

echo ""
echo "Backend en ejecución (PID ${DEV_PID}). Presioná Ctrl+C para detener."
wait "${DEV_PID}"
