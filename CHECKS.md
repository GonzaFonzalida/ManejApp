# CHECKS — Resultados de chequeos automáticos

Chequeos realizados sobre el codebase (branch backend-MG-01). Fecha de ejecución: según análisis del repo.

---

## 1. Stack identificado

| Componente | Tecnología | Evidencia |
|------------|------------|-----------|
| Runtime | Node.js | `package.json` (scripts con node, ts-node-dev), `src/index.ts` |
| Framework HTTP | Express 5.x | `package.json` → `"express": "^5.1.0"`, `src/app.ts` |
| Lenguaje | TypeScript | `tsconfig.json`, extensión `.ts` en `src/` |
| ORM / DB | Prisma + PostgreSQL | `prisma/schema.prisma`, `package.json` → `@prisma/client`, `prisma` |
| Validación | Zod, express-validator | `package.json` → `zod`, `express-validator`; schemas en `*.schemas.ts` |
| Auth | JWT (jsonwebtoken), cookies (refresh) | `package.json` → `jsonwebtoken`, `cookie`; `src/modules/auth/`, `src/shared/utils/jwtUtils.ts` |
| Pagos | Mercado Pago (mercadopago) | `package.json` → `mercadopago`; `src/modules/payments/mercadopago.service.ts` |
| Notificaciones push | Firebase Admin | `package.json` → `firebase-admin`; `src/config/firebase.ts` |
| Email | Nodemailer | `package.json` → `nodemailer`; `src/shared/services/EmailService.ts` |
| Documentación API | Swagger (swagger-jsdoc, swagger-ui-express) | `package.json`; `src/app.ts` → `/api-docs` |
| Gestor de paquetes | pnpm (recomendado) | `package.json` → `"packageManager": "pnpm@10.13.1"` |

**Conclusión:** Backend Node.js + Express + TypeScript + Prisma (PostgreSQL). No es Nest ni Django.

---

## 2. Scripts disponibles (package.json)

| Script | Comando | Qué hace |
|--------|---------|----------|
| start | `pnpm start` | Compila (`pnpm run build`) y ejecuta `node dist/index.js` |
| dev | `pnpm run dev` | Servidor en desarrollo con ts-node-dev (recarga al cambiar código) |
| build | `pnpm run build` | `tsc && tsc-alias` (compila TypeScript y resuelve path aliases) |
| dev:ngrok | `pnpm run dev:ngrok` | Ejecuta dev y ngrok en paralelo (túnel público) |
| dev:tunnel | `pnpm run dev:tunnel` | Ejecuta dev y localtunnel en paralelo |
| ngrok | `pnpm run ngrok` | Solo ngrok en puerto 3000 |
| tunnel | `pnpm run tunnel` | Solo localtunnel en puerto 3000 |
| setup:logging | `pnpm run setup:logging` | Ejecuta `scripts/setup-logging.js` |
| logs:tail | `pnpm run logs:tail` | `tail -f logs/app.log` |
| logs:clean | `pnpm run logs:clean` | Borra archivos en `logs/*.log` |

**No hay script:** `test`, `lint`, `format`. No hay configuración de Jest, Vitest, ESLint ni Prettier en `package.json`.

---

## 3. Errores de configuración obvios

### Variables de entorno

- **Inconsistencia .env.example vs config.ts:**  
  `.env.example` usa `JWT_EXPIRES_IN` y `JWT_REFRESH_EXPIRES_IN`.  
  `src/config/config.ts` espera `JWT_EXPIRATION` y `JWT_REFRESH_EXPIRATION`.  
  Si alguien copia solo `.env.example`, la validación Zod falla al arrancar.

- **COOKIE_SECRET:**  
  Requerido en `config.ts` (validación con `z.string().min(10)`). No aparece en `.env.example`. Quien copie el ejemplo tendrá error al iniciar.

**Recomendación:** Actualizar `.env.example` con los nombres exactos que usa `config.ts` y añadir `COOKIE_SECRET`. Ver TODO_BACKLOG P0-1.

### Puertos

- Puerto por defecto: 3000 (variable `PORT` en config). No hay conflicto obvio en el código; solo asegurarse de que no haya otro servicio en 3000.

### Imports rotos

- No se ejecutó una compilación completa en este entorno (no había `node_modules` instalado). Los path aliases (`@config/*`, `@shared/*`, `@auth/*`, etc.) están definidos en `tsconfig.json` y se resuelven en tiempo de ejecución con `tsconfig-paths/register` (dev) o `tsconfig-paths-bootstrap.js` (start). No se detectaron imports obviamente rotos en la revisión manual de rutas y app.

---

## 4. Tests

- **Estado:** No hay tests automatizados configurados.
- **Evidencia:** No existe script `test` en `package.json`. No hay archivos de configuración de Jest, Vitest ni Mocha en la raíz del proyecto.
- **Cómo correrlos:** N/A. Ver TODO_BACKLOG P2-1 para añadir tests.

---

## 5. Docker

- **Archivos:** `Dockerfile`, `Dockerfile.dev`, `docker-compose.yml`, `docker-compose.dev.yml`, `.dockerignore`, `start.sh`.
- **Cómo levantar:**
  - **Desarrollo (ts-node, sin compilar):**  
    `docker-compose -f docker-compose.dev.yml up --build`  
    (o `-d` para detached). Ver `README-DOCKER.md`.
  - **Producción (build + node):**  
    `docker-compose up --build`  
    (o `-d` para detached).
- **Variables en Docker:** Los compose incluyen `JWT_EXPIRATION`, `JWT_REFRESH_EXPIRATION`, `COOKIE_SECRET` (coherentes con `config.ts`). El backend espera que la base esté en el servicio `postgres` con la URL indicada en `DATABASE_URL`.
- **Inicio del backend:** `start.sh` ejecuta `npx prisma db push`, `npx prisma migrate deploy`, `npx prisma generate` y luego `node dist/index.js` (o ts-node si no existe dist). Ver README-DOCKER para más detalles.

---

## 6. Linter / formatter

- **Estado:** No hay script `lint` ni `format` en `package.json`. No se encontró configuración de ESLint ni Prettier en la raíz del proyecto.
- **Cómo correrlo:** N/A. Si se añaden más adelante, documentar en RUNBOOK.

---

## 7. Resumen de compilación (cuando haya dependencias)

- En el entorno donde se ejecutaron los chequeos no estaba instalado `node_modules` (no se corrió `pnpm install` ni `npm install`). Por tanto:
  - `pnpm run build` / `npm run build` no se ejecutaron con éxito en este entorno.
  - Se recomienda, en un entorno con dependencias instaladas, ejecutar `pnpm run build` (o `npm run build`) y corregir cualquier error de TypeScript que aparezca.
- **Prerequisito para build:** `pnpm install` o `npm install` en la raíz del proyecto.

---

*Documento generado a partir del análisis del codebase (branch backend-MG-01).*
