#!/usr/bin/env bash
# Corre la app Flutter en un iPhone conectado por USB, usando la API del Mac en la LAN.
# Prerrequisito: backend ya corriendo (p. ej. ./scripts/start-demo-backend.sh en ManejApp/).
#
# Uso:  cd ManejApp-frontend && ./scripts/run-ios-demo.sh
# Opcional: PORT=3099 ./scripts/run-ios-demo.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PORT="${PORT:-3099}"

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
  echo "ERROR: No se detectó IP LAN." >&2
  exit 1
fi

API_URL="http://${LAN_IP}:${PORT}"
CONFIG_URL="${API_URL}/api/v1/config"

echo "API_URL (dart-define): ${API_URL}"
if ! curl -sf --max-time 3 "${CONFIG_URL}" >/dev/null; then
  echo "ERROR: No responde ${CONFIG_URL}" >&2
  echo "Levantá primero el backend:  cd ../ManejApp && ./scripts/start-demo-backend.sh" >&2
  exit 1
fi
echo "✓ Backend alcanzable desde esta Mac (${CONFIG_URL})"

DEVICE="${1:-}"
if [[ -z "${DEVICE}" ]]; then
  echo ""
  echo "Dispositivos:"
  flutter devices
  echo ""
  echo "Ejecutá de nuevo pasando el id del iPhone, por ejemplo:"
  echo "  ./scripts/run-ios-demo.sh 00008110-001A648E0A80201E"
  exit 0
fi

exec flutter run --dart-define=API_URL="${API_URL}" -d "${DEVICE}"
