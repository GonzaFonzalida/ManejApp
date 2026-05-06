#!/usr/bin/env bash
# Libera puertos que el API local ha usado en distintas versiones del proyecto (evita “address already in use”).
# No toca el panel admin (Next suele usar 3001).
set -euo pipefail
for port in 3000 3099; do
  pids=$(lsof -ti:"$port" 2>/dev/null || true)
  if [ -n "${pids}" ]; then
    echo "==> Matando procesos en puerto ${port}: ${pids}"
    kill -9 ${pids} 2>/dev/null || true
  else
    echo "==> Puerto ${port}: libre"
  fi
done
echo "==> Listo."
