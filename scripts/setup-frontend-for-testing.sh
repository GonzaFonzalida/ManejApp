#!/usr/bin/env bash
# Prepara el frontend (branch frontend-TH-02) en una carpeta hermana para testeo
# con el backend en esta misma repo (backend-MG-01).
# Uso: desde la raíz del repo backend: ./scripts/setup-frontend-for-testing.sh

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND_DIR="$(dirname "$REPO_ROOT")/ManejApp-frontend"
CONFIG_FILE="$FRONTEND_DIR/lib/services/config_service.dart"

echo "==> Repo backend: $REPO_ROOT"
echo "==> Carpeta frontend: $FRONTEND_DIR"
echo ""

cd "$REPO_ROOT"

# 1. Traer branch del frontend
echo "==> Obteniendo branch frontend-TH-02..."
git fetch origin frontend-TH-02 2>/dev/null || true

# 2. Crear worktree (carpeta hermana con el frontend)
if [ -d "$FRONTEND_DIR" ]; then
  echo "==> Ya existe $FRONTEND_DIR. Actualizando y reaplicando patch..."
  cd "$FRONTEND_DIR"
  git fetch origin frontend-TH-02 2>/dev/null || true
  git checkout frontend-TH-02 2>/dev/null || true
  git pull origin frontend-TH-02 2>/dev/null || true
else
  echo "==> Creando worktree en $FRONTEND_DIR..."
  if ! git worktree add -b frontend-TH-02 "$FRONTEND_DIR" origin/frontend-TH-02 2>/dev/null; then
    # Rama ya existe: crear worktree sin -b
    git branch frontend-TH-02 origin/frontend-TH-02 2>/dev/null || true
    git worktree add "$FRONTEND_DIR" frontend-TH-02
  fi
fi

# 3. Apuntar config del frontend a localhost (backend local)
if [ -f "$CONFIG_FILE" ]; then
  if grep -q "72.60.166.178" "$CONFIG_FILE" 2>/dev/null; then
    echo "==> Parcheando config_service.dart para usar http://localhost:3099..."
    sed -i.bak 's|http://72.60.166.178:3000|http://localhost:3099|g' "$CONFIG_FILE"
    rm -f "${CONFIG_FILE}.bak"
    echo "    Listo."
  else
    echo "==> config_service.dart ya usa localhost o otro host (no se cambia)."
  fi
else
  echo "==> AVISO: No se encontró $CONFIG_FILE. ¿La estructura del branch cambió?"
fi

# 4. Flutter pub get
if command -v flutter >/dev/null 2>&1; then
  echo "==> Ejecutando flutter pub get..."
  (cd "$FRONTEND_DIR" && flutter pub get)
  echo ""
  echo "==> Frontend listo para testear."
  echo "    Para correr la app:"
  echo "      cd $FRONTEND_DIR"
  echo "      flutter run -d chrome"
  echo "    (Asegurate de tener el backend corriendo en http://localhost:3099)"
else
  echo "==> Flutter no está en el PATH. Instalalo y luego ejecutá en la carpeta frontend:"
  echo "    cd $FRONTEND_DIR"
  echo "    flutter pub get"
  echo "    flutter run -d chrome"
fi

echo ""
echo "==> Resumen:"
echo "    Backend (este repo):  cd $REPO_ROOT && pnpm run dev"
echo "    Frontend:             cd $FRONTEND_DIR && flutter run -d chrome"
