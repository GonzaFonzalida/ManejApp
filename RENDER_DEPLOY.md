# Deploy backend ManejApp en Render (Free) con Neon

Esta guia esta basada en inspeccion y pruebas reales sobre este repo.

## Estado validado en local (contra Neon)

Pruebas ejecutadas:

1. `GET http://localhost:3099/health` devolvio estado healthy y `database: connected`.
2. Verificacion de `DATABASE_URL` efectiva: el host parseado fue `ep-gentle-tree-aceevz4x.sa-east-1.aws.neon.tech` (`sslmode=require`).
3. Lectura real con Prisma:
   - `user.count()` y `session.count()` OK.
4. Escritura real con Prisma:
   - `systemConfig.create(...)` y `systemConfig.delete(...)` OK.
5. Build real:
   - `pnpm run build` OK.

## Bloqueo real detectado (Prisma migrate)

`npx prisma migrate status` contra Neon falla con `P3019`:
- `schema.prisma` usa provider `postgresql`.
- `prisma/migrations/migration_lock.toml` tiene provider `sqlite`.

Implicancia:
- **No usar `prisma migrate deploy` en Render por ahora** para esta etapa.
- Para pruebas, conviene usar `prisma db push` de forma controlada/manual.

## Configuracion recomendada en Render

### Root Directory

`ManejApp`

### Build Command (exacto recomendado)

`pnpm install --frozen-lockfile && npx prisma generate && pnpm run build`

### Start Command (exacto recomendado)

`node -r ./tsconfig-paths-bootstrap.js dist/index.js`

### Version de Node recomendada

Node 20 (alineado con `Dockerfile` y `Dockerfile.dev`: `node:20-alpine`).

En Render:
- Setear `NODE_VERSION=20`.

## Estrategia Prisma para esta etapa (Render + Neon)

Dado el conflicto de providers en historial de migraciones:

1. **Paso manual previo al primer deploy** (desde local, apuntando a Neon de Render):
   - `npx prisma generate`
   - `npx prisma db push`
2. Recien despues crear/encender servicio en Render.
3. En esta etapa de pruebas, no ejecutar `prisma migrate deploy` automatico en Start Command.

Cuando quieras formalizar migraciones versionadas para produccion:
- Normalizar historial de migraciones a `postgresql` y recien ahi habilitar `migrate deploy`.

## Variables de entorno para Render (tomadas del codigo real)

## 1) Obligatorias para levantar

- `DATABASE_URL`
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`
- `COOKIE_SECRET`
- `MERCADOPAGO_ACCESS_TOKEN`
- `MERCADOPAGO_PUBLIC_KEY`
- `MERCADOPAGO_WEBHOOK_SECRET` (obligatoria en `NODE_ENV=production` por validacion Zod)

## 2) Obligatorias para auth

- `JWT_SECRET`
- `JWT_REFRESH_SECRET`
- `COOKIE_SECRET`

Opcionales para social login:
- `GOOGLE_CLIENT_ID` (habilita login Google)
- `APPLE_CLIENT_ID` (habilita login Apple)

## 3) Obligatorias para Mercado Pago

- `MERCADOPAGO_ACCESS_TOKEN`
- `MERCADOPAGO_PUBLIC_KEY`
- `MERCADOPAGO_WEBHOOK_SECRET` (en produccion)

Condicional por split/marketplace:
- `APP_COLLECTOR_ID` (usado en `commission-payment.service.ts`)

## 4) Apple / Google / Firebase

- Google: `GOOGLE_CLIENT_ID` (si usas login Google)
- Apple: `APPLE_CLIENT_ID` (si usas login Apple)
- Firebase:
  - No hay `FIREBASE_SERVICE_ACCOUNT_KEY` leida por `src/config/firebase.ts`.
  - Usa `applicationDefault()`: si queres push real, proveer credenciales de Google en runtime (por ejemplo `GOOGLE_APPLICATION_CREDENTIALS` + archivo/secret montado segun politica de deploy).

## 5) Opcionales / secundarias

- `PORT` (default 3099)
- `APP_URL` (recomendado setear URL publica de Render)
- `APP_URL_PUBLIC` (opcional para callbacks/public URL)
- `APP_COMMISSION_PERCENTAGE` (default 20)
- `LOG_LEVEL`, `ENABLE_CONSOLE_LOGS`, `ENABLE_FILE_LOGS`, `ENABLE_DATABASE_LOGS`
- `LOG_DIRECTORY`, `LOG_FILENAME`, `LOG_MAX_SIZE`, `LOG_MAX_FILES`
- `LOG_TABLE_NAME`, `LOG_RETENTION_DAYS`
- `RATE_LIMIT_WINDOW_MS`, `RATE_LIMIT_MAX_REQUESTS`, `AUTH_RATE_LIMIT_MAX`
- `EMAIL_USER`, `EMAIL_PASS` (si queres envio real de emails)
- `MOBILE_APP_SCHEME` (deep links de email)
- `DEV_AUTO_VERIFY_EMAIL` (solo dev)
- `ENSURE_DEMO_ADMIN`, `ENSURE_DEMO_CATALOG` (solo dev/test)

## Health check en Render

Usar:
- `/health`

Este endpoint ejecuta `SELECT 1` via Prisma (`src/shared/middlewares/healthCheck.ts`), por lo tanto valida API + DB.

## Render Free y filesystem efimero: riesgos reales

Dependencias a filesystem local detectadas:
- Uploads de perfiles: `uploads/profile-images`, `uploads/profiles`
- Uploads de documentos instructor: `uploads/instructors_docs`
- Logs de archivo: `./logs`

Riesgo en Render Free:
- El filesystem no es persistente entre reinicios/redeploys.
- Archivos subidos y logs locales se pueden perder.

Conclusiones practicas:
- Para pruebas API basicas no bloquea el deploy.
- Para features de upload/log historico, migrar a storage externo (S3/Cloudinary/etc.) y logging externo.

## Panel manual vs render.yaml

Para esta etapa conviene **manual en panel de Render**:
- Menor friccion mientras cerras variables y Prisma.
- Evita introducir IaC antes de estabilizar deploy.

Crear `render.yaml` recien cuando:
- variables finales esten estables,
- estrategia Prisma quede cerrada (ya sin conflicto sqlite/postgresql).

