#!/usr/bin/env bash
# QA manual Mercado Pago Marketplace — curls seguros (sin secretos embebidos).
# Uso:
#   export API_URL="https://manejapp-1.onrender.com/api/v1"
#   export STUDENT_TOKEN="..."
#   export INSTRUCTOR_TOKEN="..."
#   export BOOKING_ID="42"
#   bash scripts/qa-mp-marketplace-e2e.sh

set -euo pipefail

API_URL="${API_URL:-https://manejapp-1.onrender.com/api/v1}"
BASE="${API_URL%/api/v1}"
BASE="${BASE%/}"

echo "=== 1) Healthcheck ==="
curl -sS "${BASE}/health" | head -c 500
echo -e "\n"

if [[ -n "${INSTRUCTOR_TOKEN:-}" ]]; then
  echo "=== 2) Status MP instructor (sin tokens en respuesta) ==="
  curl -sS -w "\nHTTP %{http_code}\n" \
    -H "Authorization: Bearer ${INSTRUCTOR_TOKEN}" \
    "${API_URL}/instructors/me/mercadopago/status"
  echo
else
  echo "=== 2) Omitido: INSTRUCTOR_TOKEN no seteado ==="
fi

if [[ -n "${STUDENT_TOKEN:-}" && -n "${BOOKING_ID:-}" ]]; then
  echo "=== 3) Crear preferencia booking (marketplace) ==="
  curl -sS -w "\nHTTP %{http_code}\n" \
    -X POST \
    -H "Authorization: Bearer ${STUDENT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "${API_URL}/payments/booking/${BOOKING_ID}/preference"
  echo

  echo "=== 4) Status pago/preferencia (identifier = bookingId) ==="
  curl -sS -w "\nHTTP %{http_code}\n" \
    -H "Authorization: Bearer ${STUDENT_TOKEN}" \
    "${API_URL}/payments/mercadopago/status/${BOOKING_ID}"
  echo
else
  echo "=== 3-4) Omitido: STUDENT_TOKEN y/o BOOKING_ID no seteados ==="
fi

if [[ -n "${STUDENT_TOKEN:-}" && -n "${BOOKING_NO_MP_ID:-}" ]]; then
  echo "=== 5) Instructor sin MP — esperado 409 INSTRUCTOR_MP_NOT_CONNECTED ==="
  curl -sS -w "\nHTTP %{http_code}\n" \
    -X POST \
    -H "Authorization: Bearer ${STUDENT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{}' \
    "${API_URL}/payments/booking/${BOOKING_NO_MP_ID}/preference"
  echo
else
  echo "=== 5) Omitido: setear BOOKING_NO_MP_ID (reserva de instructor sin MP) ==="
fi

echo "=== 6) Webhook endpoint existe (firma inválida → 401, no 404) ==="
curl -sS -o /dev/null -w "HTTP %{http_code}\n" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"type":"payment","data":{"id":"123456789"}}' \
  "${API_URL}/payments/mercadopago/webhook"

echo "Listo."
