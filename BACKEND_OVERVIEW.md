# BACKEND_OVERVIEW — ManejApp API

## 1. Qué es este backend y para qué sirve

**ManejApp** es el backend (servidor) de una aplicación para **escuelas de manejo**. Sirve para:

- **Registrar y autenticar** usuarios: estudiantes, instructores y administradores.
- **Gestionar instructores**: perfiles, permisos, vinculación con Mercado Pago.
- **Gestionar vehículos** de cada instructor (autos de la escuela).
- **Programar clases de manejo** entre estudiantes e instructores.
- **Gestionar pagos** (incluido Mercado Pago) y **comisiones** (ej. 20% app, 80% instructor).
- **Horarios (slots)**: crear y reservar turnos para clases.
- **Mensajes** entre usuarios (conversaciones).
- **Notificaciones push** (Firebase) y **emails** (verificación, reportes).
- **Panel de administración**: estadísticas, salud del sistema, gestión de usuarios y reportes.

En resumen: es la “cabeza” que recibe peticiones desde una app móvil o web, valida datos, guarda en base de datos y responde. No incluye la interfaz visual; solo la lógica y los datos.

---

## 2. Cómo se corre localmente (paso a paso)

### Prerrequisitos

- **Node.js** (v18 o superior recomendado).
- **pnpm** (el proyecto usa `pnpm`; ver `package.json` → `"packageManager": "pnpm@10.13.1"`).
- **PostgreSQL** (v15 recomendado) instalado y corriendo, con una base de datos creada para ManejApp.

### Pasos

1. **Clonar / abrir el repo** y ubicarse en la raíz del proyecto.

2. **Instalar dependencias**
   ```bash
   pnpm install
   ```

3. **Configurar variables de entorno**
   - Copiar `.env.example` a `.env`.
   - **Importante:** En `config.ts` el backend espera `JWT_EXPIRATION` y `JWT_REFRESH_EXPIRATION` (y `COOKIE_SECRET`). En `.env.example` aparecen `JWT_EXPIRES_IN` y `JWT_REFRESH_EXPIRES_IN` y no está `COOKIE_SECRET`. Debes usar los nombres que lee el código:
     - `JWT_EXPIRATION`, `JWT_REFRESH_EXPIRATION`, `COOKIE_SECRET`.
   - Completar al menos: `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`, `COOKIE_SECRET`, `MERCADOPAGO_ACCESS_TOKEN`, `MERCADOPAGO_PUBLIC_KEY`.

4. **Preparar la base de datos**
   - Opción A — Solo Prisma (tablas del schema):
     ```bash
     npx prisma generate
     npx prisma db push
     ```
   - Opción B — Migraciones versionadas:
     ```bash
     npx prisma generate
     npx prisma migrate deploy
     ```
   - Tablas que **no** están en migraciones de Prisma y pueden requerir scripts SQL manuales (según cómo esté tu DB): `blacklisted_tokens`, `payment_recovery_logs`, `logs`. Ver `sql/` y `scripts/` (ej. `setup-blacklisted-tokens.js`, `setup-logging.js`).

5. **Arrancar el servidor**
   - Desarrollo (recarga al cambiar código):
     ```bash
     pnpm run dev
     ```
   - Producción (compilar y ejecutar):
     ```bash
     pnpm run build
     pnpm start
     ```
   Por defecto el servidor escucha en el puerto **3000** (configurable con `PORT` en `.env`).

### Comandos útiles

| Comando | Qué hace |
|--------|-----------|
| `pnpm run dev` | Servidor en modo desarrollo con recarga automática |
| `pnpm run build` | Compila TypeScript a `dist/` |
| `pnpm start` | Compila y ejecuta el servidor (producción) |
| `npx prisma studio` | Abre interfaz web para ver/editar la base de datos |
| `pnpm run setup:logging` | Configura logging (ejecuta `scripts/setup-logging.js`) |
| `pnpm run logs:tail` | Sigue el archivo de log en tiempo real |

---

## 3. Variables de entorno necesarias

Se leen en `src/config/config.ts` (validación con Zod). Nombres **exactos** y ejemplo de valores:

| Variable | Ejemplo de valor | Dónde se usa |
|----------|------------------|--------------|
| `DATABASE_URL` | `postgresql://user:pass@localhost:5432/manejapp` | Conexión a PostgreSQL (Prisma) |
| `JWT_SECRET` | Una clave larga y secreta (≥10 caracteres) | Firma del token de acceso |
| `JWT_REFRESH_SECRET` | Otra clave larga y secreta | Firma del refresh token |
| `JWT_EXPIRATION` | `15m` | Tiempo de vida del token de acceso |
| `JWT_REFRESH_EXPIRATION` | `7d` | Tiempo de vida del refresh token |
| `COOKIE_SECRET` | Una clave larga y secreta | Cookies (ej. refresh token) |
| `NODE_ENV` | `development` o `production` | Entorno de ejecución |
| `PORT` | `3000` | Puerto del servidor |
| `MERCADOPAGO_ACCESS_TOKEN` | `APP_USR-...` | API Mercado Pago |
| `MERCADOPAGO_PUBLIC_KEY` | `APP_USR-...` | Clave pública Mercado Pago |
| `APP_URL` | `http://localhost:3000` | URL base del backend (MP callbacks, etc.) |
| `APP_URL_PUBLIC` | (opcional) URL pública si usas túnel (ngrok) | Usado en desarrollo para MP |
| `LOG_LEVEL` | `info` | Nivel de log (error, warn, info, debug) |
| `LOG_DIRECTORY` | `./logs` | Carpeta de archivos de log |
| `RATE_LIMIT_WINDOW_MS` | `900000` | Ventana del rate limit (ms) |
| `RATE_LIMIT_MAX_REQUESTS` | `100` | Máximo de peticiones por ventana |
| `AUTH_RATE_LIMIT_MAX` | `5` | Límite en rutas de login/refresh |

Otras variables que aparecen en `.env.example` pero **no** en `config.ts` (se usan en otros archivos vía `process.env`): `MERCADOPAGO_WEBHOOK_SECRET`, `APP_COMMISSION_PERCENTAGE`, `APP_COLLECTOR_ID`, `FIREBASE_SERVICE_ACCOUNT_KEY`, `EMAIL_*`, `REPORT_*`, etc. Si las usas, debes definirlas en `.env` según la documentación o los archivos que las referencien.

**Inconsistencia detectada:** `.env.example` usa `JWT_EXPIRES_IN` y `JWT_REFRESH_EXPIRES_IN`; el código en `config.ts` usa `JWT_EXPIRATION` y `JWT_REFRESH_EXPIRATION`. Si copias solo el ejemplo, la app puede fallar al iniciar. Debes alinear nombres o documentar cuáles usa el código.

---

## 4. Estructura del proyecto (carpetas y archivos clave)

| Ruta | Para qué sirve |
|------|-----------------|
| `src/index.ts` | Punto de entrada: construye la app y pone el servidor a escuchar en `PORT`. |
| `src/app.ts` | Construye Express: middlewares de seguridad, CORS, rate limit, rutas API v1, Swagger, manejo de errores. |
| `src/config/config.ts` | Carga y valida variables de entorno. |
| `src/config/prismaClient.ts` | Cliente de Prisma (acceso a la base de datos). |
| `src/config/firebase.ts` | Configuración de Firebase (notificaciones push). |
| `src/modules/` | Módulos por dominio: auth, users, instructors, permissions, cars, drivingClass, payments, schedule, notifications, messages, admin. |
| `src/modules/<nombre>/` | Por cada módulo: `*.routes.ts` (rutas HTTP), `*.controller.ts` (manejan request/response), `*.services.ts` o `*.service.ts` (lógica de negocio), `*.schemas.ts` (validación Zod), `repositories/` (acceso a datos con Prisma). |
| `src/shared/middlewares/` | Middlewares globales: auth, errores, validación, seguridad, health, etc. |
| `src/shared/services/` | Servicios compartidos: email, logging, auditoría, blacklist de JWT, reportes, cron (SchedulerService). |
| `src/shared/DiContainer/container.ts` | Inyección de dependencias: registra repositorios, servicios y controladores usados en la app. |
| `prisma/schema.prisma` | Modelo de datos (tablas y relaciones). |
| `prisma/migrations/` | Migraciones versionadas de la base de datos. |
| `sql/` | Scripts SQL manuales (logs, blacklisted_tokens, payment_recovery, etc.) no generados por Prisma. |
| `scripts/` | Scripts Node (crear admin, configurar logging, blacklist, payment recovery, etc.). |
| `docs/` | Documentación adicional (arquitectura, pagos, seguridad, etc.). |

---

## 5. Flujo de una petición típica

1. **Request**  
   El cliente (app móvil o web) envía una petición HTTP (ej. `POST /api/v1/auth/login` con email y contraseña).

2. **Middlewares globales (en orden en `app.ts`)**  
   - Helmet, CORS, rate limit.  
   - Prevención de SQL injection y XSS, sanitización.  
   - Logging de request y de rendimiento.  
   - `express.json()` para leer el body.

3. **Ruta**  
   Express envía la petición a la ruta correspondiente (ej. `app.use("/api/v1/auth", authRouter)` → `auth.routes.ts`).

4. **Middlewares de ruta**  
   - Rate limit específico (ej. en login).  
   - Validación del body/params (Zod).  
   - Autenticación (`authenticate`) si la ruta lo requiere.

5. **Controller**  
   El controller (ej. `auth.controller.ts`) recibe `req` y `res`, extrae datos y llama al **service**.

6. **Service**  
   El service (ej. `auth.services.ts`) contiene la lógica: verificar usuario, comparar contraseña, crear sesión, generar JWT, etc. Usa **repositories** (Prisma) para leer/escribir en la base de datos.

7. **Base de datos**  
   Los repositorios usan el cliente de Prisma (`prisma`) para ejecutar consultas (crear usuario, buscar por email, crear sesión, etc.).

8. **Respuesta**  
   El controller devuelve JSON al cliente (token, usuario, lista, etc.) o llama a `next(error)` para que el **middleware de errores** (`errorMiddleware.ts`) responda con el código y mensaje adecuados.

---

## 6. Módulos / features: completos vs incompletos

| Módulo / feature | Estado | Evidencia |
|------------------|--------|-----------|
| Auth (login, refresh, logout, me, sessions, revoke) | Completo | `auth.routes.ts`, `auth.controller.ts`, `auth.services.ts` con JWT y sesiones. |
| Registro de usuarios (students) | Completo | `user.routes.ts` → `POST /register`, `user.controller` + `user.services`. |
| Registro de instructores | Completo | `instructor.routes.ts` → `POST /register`, controller + service. |
| Usuarios (CRUD, perfil, verificación email, imagen, FCM) | Completo | Rutas en `user.routes.ts`; servicios y repositorios presentes. |
| Permisos (CRUD) | Incompleto | `permissions.routes.ts` línea 18: `DELETE /:id` llama a `controller.getById` en lugar de un método delete. Comentario en código: "falta delete". |
| Cars (CRUD, por instructor, toggle estado) | Completo | `improved-cars.routes.ts` y servicio con Prisma. |
| Clases de manejo (CRUD, cancelar) | Completo | `drivingClass/routes.ts` y controller con Prisma. |
| Pagos (crear, listar, Mercado Pago, webhook) | Completo | `functional-payment.routes.ts`, `commission.routes.ts`; webhook sin auth. |
| Comisiones (reporte, ganancias instructor) | Completo | `commission.routes.ts` y servicios asociados. |
| Schedule (slots, reservar, cancelar) | Completo | `schedule.routes.ts` y `schedule.service.ts`. |
| Notificaciones (enviar por usuario/rol/broadcast, token) | Completo | `notifications/routes.ts` y controller; rutas usan `/send-to-user`, `/send-to-role`, `/broadcast`, `/token`. |
| Mensajes (enviar, conversaciones, leer) | Completo | `messages.routes.ts` con auth y validación. |
| Admin (dashboard, health, manage user, reportes) | Completo | `admin.routes.ts` con auth y rol ADMIN. |
| Payment recovery (cron) | Parcial | `payment-recovery.service.ts` y `payment-recovery.controller.ts` existen pero **no** están montados en `app.ts`; solo se usa desde `SchedulerService` (cron). No hay rutas HTTP expuestas. |
| Logging a DB y archivo | Parcial | Hay `DatabaseTransport` y scripts en `sql/create_logs_table.sql`; la tabla `logs` no está en el schema de Prisma (se crea por SQL manual). |
| Blacklist de JWT | Completo | Servicio y uso en logout; tabla en schema Prisma (`BlacklistedToken`). Migración: depende de si se usó `db push` o migraciones; scripts en `sql/` para crear tablas manualmente. |
| Tests automatizados | No encontrado | No hay script `test` en `package.json` ni configuración de Jest/Vitest/Mocha. |
| Documentación Swagger | Parcial | Swagger configurado en `app.ts` y algunos endpoints documentados (ej. auth); no todos los endpoints están documentados con JSDoc. |

---

*Documento generado a partir del análisis del codebase (branch backend-MG-01).*
