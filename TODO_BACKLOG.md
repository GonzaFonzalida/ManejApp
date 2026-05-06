# TODO_BACKLOG — Backlog priorizado para terminar el proyecto

## P0 — Bloqueante

### P0-1. Alinear variables de entorno (.env.example vs config.ts)

- **Qué hay que hacer:** Hacer que `.env.example` use exactamente los mismos nombres que lee `src/config/config.ts`, y añadir `COOKIE_SECRET`. Si el código acepta ambos nombres (JWT_EXPIRES_IN y JWT_EXPIRATION), documentar cuál es el oficial.
- **Por qué importa:** Si alguien copia solo `.env.example`, la app falla al arrancar por validación Zod (variables faltantes o nombres incorrectos).
- **Archivos involucrados:** `.env.example`, `src/config/config.ts`, opcionalmente `README-DOCKER.md`, `docker-compose.yml`, `docker-compose.dev.yml`.
- **Pasos concretos:** 1) En `.env.example` reemplazar `JWT_EXPIRES_IN` por `JWT_EXPIRATION` y `JWT_REFRESH_EXPIRES_IN` por `JWT_REFRESH_EXPIRATION`. 2) Añadir `COOKIE_SECRET="..."` con un valor de ejemplo. 3) Revisar docs y Docker para que usen los mismos nombres.
- **Criterio de listo:** Copiar `.env.example` a `.env`, completar solo valores mínimos (DATABASE_URL, JWT_*, COOKIE_SECRET), ejecutar `pnpm run dev` y que el servidor arranque sin error de validación de env.

---

### P0-2. Arreglar DELETE de permisos (usa getById en vez de delete)

- **Qué hay que hacer:** En la ruta `DELETE /api/v1/permissions/:id` llamar a un método que realmente elimine el permiso (ej. `controller.delete` o `controller.deleteById`), no `controller.getById`.
- **Por qué importa:** Hoy el endpoint no borra nada; es un bug funcional.
- **Archivos involucrados:** `src/modules/permissions/permissions.routes.ts` (línea 18), `src/modules/permissions/permissions.controller.ts` (añadir método delete si no existe).
- **Pasos concretos:** 1) En el controller, implementar un método que borre el permiso por ID (usando el servicio/repositorio). 2) En `permissions.routes.ts`, cambiar `controller.getById` por ese método en la ruta DELETE.
- **Criterio de listo:** Llamar `DELETE /api/v1/permissions/:id` con un ID válido y que el permiso desaparezca de la base de datos; respuesta HTTP coherente (ej. 204 o 200 con mensaje).

---

### P0-3. Dejar la base de datos lista (migraciones y tablas auxiliares)

- **Qué hay que hacer:** Asegurar que todas las tablas usadas por el código existan: o bien vía Prisma (migraciones o `db push`), o bien ejecutando los scripts SQL/Node documentados. Incluye: tablas del schema Prisma (User, Session, BlacklistedToken, PaymentRecoveryLog, etc.) y, si se usa logging a DB, la tabla `logs`.
- **Por qué importa:** Sin tablas correctas, el backend falla en login (blacklist), reportes (PaymentRecoveryLog), o logging a DB.
- **Archivos involucrados:** `prisma/schema.prisma`, `prisma/migrations/`, `sql/create_logs_table.sql`, `sql/create_blacklisted_tokens_table.sql`, `scripts/setup-logging.js`, `scripts/setup-blacklisted-tokens.js`, `DATA_MODEL.md`, `RUNBOOK.md`.
- **Pasos concretos:** 1) Decidir estrategia: solo Prisma o Prisma + SQL manual. 2) Si solo Prisma: generar migración para cualquier modelo que falte en migraciones (BlacklistedToken, PaymentRecoveryLog) y documentar que `logs` no está en Prisma. 3) Si se usa tabla logs: documentar en RUNBOOK que hay que ejecutar `sql/create_logs_table.sql` o `scripts/setup-logging.js`. 4) Actualizar RUNBOOK con el orden exacto de comandos para “dejar la DB lista”.
- **Criterio de listo:** En un entorno limpio (DB vacía), seguir RUNBOOK y que el servidor arranque, login funcione y logout blacklistee el token (sin errores de “tabla no existe”).

---

## P1 — Importante

### P1-1. Implementar envío de email de alerta en ReportService

- **Qué hay que hacer:** En `sendErrorAlert` de ReportService, en lugar de solo `console.error`, enviar un email de alerta (usando EmailService o similar) a los destinatarios configurados.
- **Por qué importa:** Las alertas de errores críticos deben llegar a los administradores.
- **Archivos involucrados:** `src/shared/services/ReportService.ts` (línea 253, TODO).
- **Pasos concretos:** 1) Obtener lista de emails de alerta (ej. variable de entorno o SystemConfig). 2) Llamar al servicio de email con asunto y cuerpo que incluyan error y contexto. 3) Manejar errores de envío (log, no fallar el flujo).
- **Criterio de listo:** Al dispararse una alerta de error crítico (según cómo se llame a `sendErrorAlert`), se envía un email a los destinatarios configurados.

---

### P1-2. Documentar o exponer payment recovery (opcional por API)

- **Qué hay que hacer:** Hoy la recuperación de pagos corre por cron (SchedulerService). Decidir si hace falta un endpoint HTTP (ej. para que un admin dispare una recuperación manual) y, si sí, montar las rutas del `payment-recovery.controller` en `app.ts`. Si no, al menos documentar en API_MAP y RUNBOOK que la recuperación es solo vía cron.
- **Por qué importa:** Claridad operativa y, si se necesita, capacidad de ejecutar recuperación bajo demanda.
- **Archivos involucrados:** `src/app.ts`, `src/modules/payments/payment-recovery.controller.ts`, `API_MAP.md`, `RUNBOOK.md`.
- **Pasos concretos:** Si se añade API: 1) Crear router que use el payment-recovery controller. 2) Montar en `app.ts` bajo `/api/v1/payments` o similar. 3) Proteger con auth (ej. solo ADMIN). 4) Documentar en API_MAP. Si no: solo actualizar documentación indicando que es cron.
- **Criterio de listo:** Comportamiento decidido y documentado; si hay endpoint, probado y listado en API_MAP.

---

### P1-3. Revisar y endurecer auth en rutas sensibles

- **Qué hay que hacer:** Revisar rutas que hoy no exigen auth (listadas como “No**” en API_MAP) y decidir cuáles deben ser privadas (ej. listar usuarios, permisos, clases, slots, notificaciones). Añadir middleware `authenticate` (y `requireRole` donde corresponda) en esas rutas.
- **Por qué importa:** Evitar que cualquiera pueda listar usuarios, permisos o gestionar recursos sin estar logueado.
- **Archivos involucrados:** `src/modules/users/user.routes.ts`, `src/modules/permissions/permissions.routes.ts`, `src/modules/drivingClass/routes.ts`, `src/modules/schedule/schedule.routes.ts`, `src/modules/notifications/routes.ts`, y otros que figuren sin auth en API_MAP.
- **Pasos concretos:** 1) Listar endpoints que deben ser privados. 2) Añadir `authenticate` (y opcionalmente `requireRole`) en las rutas correspondientes. 3) Actualizar API_MAP con “Sí” donde corresponda.
- **Criterio de listo:** Rutas sensibles devuelven 401 si no se envía token válido; documentación actualizada.

---

## P2 — Mejoras

### P2-1. Añadir tests automatizados

- **Qué hay que hacer:** Introducir un framework de tests (Jest o Vitest), añadir script `test` en `package.json`, y escribir al menos tests de smoke (health, login) y un par de endpoints críticos (ej. registro, crear clase).
- **Por qué importa:** Hoy no hay tests; cualquier cambio puede romper funcionalidad sin detección.
- **Archivos involucrados:** `package.json`, nuevo archivo de config de Jest/Vitest, carpetas `src/__tests__` o `tests/`, y los módulos bajo test.
- **Pasos concretos:** 1) Instalar Jest o Vitest y tipos. 2) Configurar para TypeScript y opcionalmente supertest para HTTP. 3) Añadir `"test": "jest"` (o equivalente) en `package.json`. 4) Escribir tests para `/health`, login y al menos un endpoint protegido.
- **Criterio de listo:** `pnpm test` (o `npm test`) ejecuta los tests y pasan; documentado en RUNBOOK.

---

### P2-2. Corregir cálculo de responseTime en errorMiddleware

- **Qué hay que hacer:** En `src/shared/middlewares/errorMiddleware.ts`, `responseTime` se calcula como `time - time` (siempre 0). Debe calcularse respecto al momento en que empezó la request (ej. guardando `req.startTime` en un middleware previo y restando aquí).
- **Por qué importa:** Los logs de errores tendrían un tiempo de respuesta real para análisis.
- **Archivos involucrados:** `src/shared/middlewares/errorMiddleware.ts`, posiblemente un middleware que setee `req.startTime` (si no existe, el requestLogger ya puede tener algo similar).
- **Pasos concretos:** 1) Ver si ya existe algo como `req.startTime` o `req._startTime`. 2) En errorHandler, calcular `responseTime = Date.now() - (req.startTime || req._startTime || time)` y usarlo en el log.
- **Criterio de listo:** Al provocar un error, el log del error incluye un responseTime distinto de 0 cuando la request tardó algo.

---

### P2-3. Completar documentación Swagger de todos los endpoints

- **Qué hay que hacer:** Añadir JSDoc con anotaciones OpenAPI para los endpoints que faltan (usuarios, instructores, clases, pagos, schedule, notificaciones, mensajes, admin) para que Swagger UI muestre parámetros, body y respuestas.
- **Por qué importa:** Mejor experiencia para quien consuma la API.
- **Archivos involucrados:** Controladores y/o rutas de cada módulo (donde estén los handlers), `app.ts` (apis en swaggerJSDoc).
- **Pasos concretos:** 1) Revisar qué endpoints ya tienen @swagger en el controller. 2) Añadir bloques @swagger en el resto de endpoints siguiendo el mismo estilo. 3) Verificar que `/api-docs` muestre todas las rutas documentadas.
- **Criterio de listo:** Todos los endpoints listados en API_MAP aparecen en Swagger con descripción, body/params y al menos una respuesta.

---

## Plan sugerido por fases

1. **Fase “hacer que arranque”:** P0-1 (env), P0-3 (DB). Objetivo: cualquier persona pueda clonar, copiar .env, ejecutar comandos de RUNBOOK y tener el servidor arriba sin errores de config o tablas faltantes.
2. **Fase “cerrar bugs críticos”:** P0-2 (DELETE permisos). Objetivo: que ningún endpoint declarado haga algo incorrecto (ej. get en vez de delete).
3. **Fase “cerrar endpoints y auth”:** P1-2 (payment recovery opcional), P1-3 (auth en rutas sensibles). Objetivo: API coherente y segura.
4. **Fase “operación y alertas”:** P1-1 (email de alerta). Objetivo: que los errores críticos lleguen por email.
5. **Fase “calidad y documentación”:** P2-1 (tests), P2-2 (responseTime), P2-3 (Swagger). Objetivo: tests verdes, logs útiles y API documentada.

---

## TODO / FIXME / WIP / HACK encontrados

| Texto | Archivo | Línea | Nota |
|-------|---------|-------|------|
| TODO: Implementar envío de email de alerta | `src/shared/services/ReportService.ts` | 253 | Ver P1-1. |
| falta delete | `src/modules/permissions/permissions.routes.ts` | 18 | DELETE llama a getById; ver P0-2. |

No se encontraron FIXME, WIP ni HACK con ese nombre exacto en el codebase; solo los anteriores como TODO o comentario explícito (“falta delete”).

---

*Documento generado a partir del análisis del codebase (branch backend-MG-01).*
