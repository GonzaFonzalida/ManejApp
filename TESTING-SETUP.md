# Guía para testeo funcional: Backend + Frontend

Esta guía explica cómo tener **backend** (branch `backend-MG-01`) y **frontend** (branch `frontend-TH-02`) funcionando juntos para hacer pruebas de integración en tu máquina.

---

## Flujo rápido (Opción 1 — todo listo para testear)

Seguí estos pasos en orden. El script prepara el frontend en una carpeta hermana y lo deja apuntando al backend local.

### Paso 1: Backend (esta carpeta, branch `backend-MG-01`)

```bash
# Estás en la raíz del repo (ManejApp o ManejApp-backend)
cp .env.example .env
# Editá .env y completá al menos: DATABASE_URL, JWT_SECRET, JWT_REFRESH_SECRET, COOKIE_SECRET, MERCADOPAGO_ACCESS_TOKEN, MERCADOPAGO_PUBLIC_KEY

pnpm install
npx prisma generate
npx prisma db push
pnpm run dev
```

Dejá esta terminal abierta. El backend debe quedar en **http://localhost:3000**. Probá en otra terminal: `curl http://localhost:3000/health` y `curl http://localhost:3000/api/v1/config`.

### Paso 2: Preparar el frontend (carpeta hermana)

En **otra terminal**, desde la raíz del mismo repo (donde está el backend):

```bash
./scripts/setup-frontend-for-testing.sh
```

Ese script:
- Crea la carpeta hermana `../ManejApp-frontend` con el branch `frontend-TH-02` (usa `git worktree`).
- Parchea `lib/services/config_service.dart` para usar `http://localhost:3000`.
- Ejecuta `flutter pub get` si tenés Flutter en el PATH.

### Paso 3: Correr la app Flutter

```bash
cd ../ManejApp-frontend
flutter run -d chrome
```

(O `flutter run -d <id-emulador>` para Android; en ese caso, si el backend no se ve, cambiá en `lib/services/config_service.dart` la URL a `http://10.0.2.2:3000`.)

Listo: backend en 3000, frontend en Chrome (o emulador) apuntando al backend. Podés probar login, registro y el resto de la app.

---

## Resumen rápido

- **Backend:** API Node/Express en el puerto 3000 (branch `backend-MG-01`).
- **Frontend:** App Flutter (branch `frontend-TH-02`) en carpeta hermana `ManejApp-frontend`, ya configurada para `http://localhost:3000`.
- Hay dos formas de organizar el código: **dos carpetas** (Opción 1, con script) o **una sola carpeta** (merge de branches, Opción B).

---

## Opción A: Dos carpetas (detalle)

Usás dos carpetas: en una tenés el backend (esta repo), en la otra el frontend. El script `scripts/setup-frontend-for-testing.sh` deja el frontend listo en `../ManejApp-frontend`.

### 1. Backend (carpeta actual)

- Repo en branch `backend-MG-01`.
- Copiá `.env.example` a `.env` y completá las variables (nombres exactos: `JWT_EXPIRATION`, `JWT_REFRESH_EXPIRATION`, `COOKIE_SECRET`; ver `.env.example`).
- `pnpm install`, `npx prisma generate`, `npx prisma db push`, `pnpm run dev`.
- Backend en **http://localhost:3000**.

### 2. Frontend (carpeta hermana, con script)

- Ejecutá desde la raíz del repo: `./scripts/setup-frontend-for-testing.sh`.
- Eso crea `../ManejApp-frontend` con el branch `frontend-TH-02` y ya parcheado para localhost.
- Luego: `cd ../ManejApp-frontend`, `flutter run -d chrome`.

Si en vez del script preferís hacerlo a mano: cloná el repo en otra carpeta, `git checkout frontend-TH-02`, y en `lib/services/config_service.dart` poné `_baseUrl` y `_fallbackUrl` en `http://localhost:3000`.

---

## Opción B: Una sola carpeta (merge)

Querés tener backend y frontend en el mismo directorio (por ejemplo para un solo `docker-compose` o scripts unificados más adelante).

1. En tu repo, desde `backend-MG-01`:
   ```bash
   git checkout backend-MG-01
   git pull origin backend-MG-01
   git merge origin/frontend-TH-02
   ```
   Resolvé conflictos si los hay (backend suele estar en `src/`, frontend en `lib/`, `android/`, `ios/`, `web/`, `pubspec.yaml`, etc.).

2. En la misma raíz:
   - **Backend:** mismo proceso que en Opción A (`.env`, `prisma`, `pnpm run dev`).
   - **Frontend:** `flutter pub get` y el mismo cambio en `lib/services/config_service.dart` para `_fallbackUrl` / `_baseUrl` a `http://localhost:3000` (o `10.0.2.2:3000` en Android).

3. Corré backend en una terminal y Flutter en otra (igual que en Opción A).

---

## Qué hace el backend para el frontend

- **GET /api/v1/config**  
  Devuelve `{ "baseUrl": "<APP_URL>" }`. El frontend (Flutter) usa esto para saber la URL base de la API. En local, con `APP_URL=http://localhost:3000`, el frontend puede consumir todo desde ahí.

- **CORS**  
  En desarrollo el backend permite orígenes como `http://localhost:3000`, `3001`, `8080`, `5353` y `127.0.0.1` en esos puertos, para que Flutter web no tenga bloqueos por CORS.

---

## Resumen de pasos para una sesión de testeo

1. **Backend (siempre primero)**  
   - Carpeta en `backend-MG-01`.  
   - `.env` con `APP_URL=http://localhost:3000`, resto según RUNBOOK.  
   - `pnpm run dev` → servidor en **http://localhost:3000**.

2. **Frontend**  
   - Carpeta en `frontend-TH-02` (o mismo repo después del merge).  
   - En `lib/services/config_service.dart`: `_fallbackUrl` y `_baseUrl` a `http://localhost:3000` (web) o `http://10.0.2.2:3000` (emulador Android).  
   - `flutter run -d chrome` o `flutter run -d <android>`.

3. **Probar**  
   - En la app: login, registro, pantallas que llamen a la API.  
   - Revisar en DevTools/Network que las peticiones vayan a `http://localhost:3000/api/v1/...` (o a la URL que hayas configurado).

---

## Si el backend está en otra máquina o con túnel

- Si el backend no está en la misma PC (por ejemplo está en un servidor o usás ngrok/localtunnel), poné en el frontend la URL que corresponda (ej. `https://xxx.ngrok.io` o `http://IP:3000`) en `config_service.dart` (`_fallbackUrl` / `_baseUrl`).
- En el backend, en producción o con túnel, configurá `APP_URL` con esa URL y añadí ese origen en CORS en `src/shared/middlewares/security.ts` (en producción reemplazá `https://yourdomain.com` por tu dominio real).

Con esto tenés backend y frontend listos para testeo funcional en tu entorno local o con túnel.

---

## ⚠️ CRÍTICO: Backend debe estar corriendo

**Antes de abrir la app Flutter, iniciá el backend.** Si no, verás:
*"No se pudo conectar con el servidor..."*

```bash
# Opción recomendada (libera el puerto si está ocupado):
cd /ruta/al/ManejApp
./scripts/start-dev.sh

# O directamente:
npm run dev
```

**Dejá esa terminal abierta** mientras usás la app. Cuando veas `Server corriendo en el puerto 3000`, podés abrir Flutter.

El frontend reintenta automáticamente 3 veces ante errores de conexión; si sigue fallando, el mensaje indicará que ejecutes el script anterior.

---

## Errores comunes al testear

| Problema | Qué hacer |
|----------|-----------|
| Backend no arranca: "JWT_SECRET debe tener..." o "COOKIE_SECRET..." | Usá los nombres exactos de `.env.example`: `JWT_EXPIRATION`, `JWT_REFRESH_EXPIRATION`, `COOKIE_SECRET`. Copiá de `.env.example` a `.env` y completá los valores. |
| Backend: "Database connection failed" | PostgreSQL debe estar corriendo. Revisá `DATABASE_URL` en `.env`. Ejecutá `npx prisma db push` (o `migrate deploy`). |
| Script `setup-frontend-for-testing.sh` no encuentra el branch | Ejecutá `git fetch origin frontend-TH-02` desde la raíz del repo y volvé a correr el script. |
| "No se pudo conectar. ¿Está el backend corriendo?" | El backend no está corriendo. Ejecutá `./scripts/start-backend.sh` o `npm run dev` en la carpeta del backend y dejalo abierto. |
| Flutter web: errores de CORS | El backend ya permite localhost en cualquier puerto. Asegurate de que el backend esté en 3000 y que `config_service.dart` use `http://localhost:3000`. |
| Emulador Android no alcanza el backend | En `ManejApp-frontend/lib/services/config_service.dart` usá `http://10.0.2.2:3000` en vez de `localhost`. |
