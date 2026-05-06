# API_MAP — Mapa de endpoints HTTP

Base URL: `/api/v1` (salvo `/health` y `/api-docs`).

| Método | Ruta completa | Qué hace (simple) | Qué recibe | Qué devuelve | Auth | Archivo(s) | Estado |
|--------|----------------|-------------------|------------|--------------|------|------------|--------|
| GET | `/health` | Comprueba si el servidor y la DB responden | — | JSON: status, uptime, services | No | `src/shared/middlewares/healthCheck.ts` | OK |
| GET | `/api/v1/config` | Devuelve baseUrl para el frontend (Flutter) | — | `{ baseUrl: string }` | No | `src/app.ts` | OK |
| GET | `/api-docs` | Sirve la documentación Swagger UI | — | HTML (Swagger) | No | `src/app.ts` | OK |
| POST | `/api/v1/auth/login` | Inicia sesión con email y contraseña | Body: email, password | token, user (y cookie refresh) | No | `src/modules/auth/auth.routes.ts` | OK |
| POST | `/api/v1/auth/refresh` | Renueva el token de acceso con el refresh (cookie) | Cookie httpOnly con refresh | token | No | `src/modules/auth/auth.routes.ts` | OK |
| POST | `/api/v1/auth/logout` | Cierra sesión (blacklist del token) | (opcional) token/cookie | — | No* | `src/modules/auth/auth.routes.ts` | OK |
| GET | `/api/v1/auth/me` | Devuelve el usuario actual | — | user | Sí | `src/modules/auth/auth.routes.ts` | OK |
| GET | `/api/v1/auth/sessions` | Lista sesiones activas del usuario | — | sessions | Sí | `src/modules/auth/auth.routes.ts` | OK |
| POST | `/api/v1/auth/google` | Login con Google | Body: token | token, user | No | `src/modules/auth/auth.routes.ts` | OK |
| POST | `/api/v1/auth/revoke/:sessionId` | Revoca una sesión | Params: sessionId | — | Sí | `src/modules/auth/auth.routes.ts` | OK |
| POST | `/api/v1/auth/revoke-all` | Revoca todas las sesiones del usuario | — | — | Sí | `src/modules/auth/auth.routes.ts` | OK |
| GET | `/api/v1/users` | Lista usuarios (posible filtro por query) | Query opcional | usuarios | No** | `src/modules/users/user.routes.ts` | OK |
| GET | `/api/v1/users/role/:role` | Usuarios por rol | Params: role | usuarios | No** | `src/modules/users/user.routes.ts` | OK |
| GET | `/api/v1/users/:value` | Obtiene usuario por ID o valor | Params: value | user | No** | `src/modules/users/user.routes.ts` | OK |
| PUT | `/api/v1/users/:id` | Actualiza usuario | Params: id, Body: datos | user | Sí | `src/modules/users/user.routes.ts` | OK |
| POST | `/api/v1/users/register` | Registro de usuario (estudiante) | Body: registerSchema | user | No | `src/modules/users/user.routes.ts` | OK |
| POST | `/api/v1/users/login` | Login (duplicado con auth?) | Body: loginSchema | — | No | `src/modules/users/user.routes.ts` | Posible duplicado |
| POST | `/api/v1/users/verify-email` | Verificación de email (body) | Body: token | — | No | `src/modules/users/user.routes.ts` | OK |
| GET | `/api/v1/users/verify-email/:token` | Verificación de email por URL | Params: token | — | No | `src/modules/users/user.routes.ts` | OK |
| GET | `/api/v1/users/verification-status/:userId` | Estado de verificación (para polling sin auth) | Params: userId | `{ verified: boolean }` | No | `src/modules/users/user.routes.ts` | OK |
| POST | `/api/v1/users/resend-verification` | Reenvía email de verificación | Body (ej. email) | — | No | `src/modules/users/user.routes.ts` | OK |
| POST | `/api/v1/users/forgot-password` | Solicita recuperación de contraseña | Body: email | — | No | `src/modules/users/user.routes.ts` | OK |
| POST | `/api/v1/users/reset-password` | Resetea contraseña con token | Body: token, newPassword | — | No | `src/modules/users/user.routes.ts` | OK |
| GET | `/api/v1/users/notification-preferences` | Preferencias de notificaciones | — | prefs | No** | `src/modules/users/user.routes.ts` | OK |
| PUT | `/api/v1/users/notification-preferences` | Actualiza preferencias de notificaciones | Body: prefs | — | No** | `src/modules/users/user.routes.ts` | OK |
| POST | `/api/v1/users/:id/upload-profile-image` | Sube imagen de perfil | Params: id, multipart: image | — | Sí | `src/modules/users/user.routes.ts` | OK |
| POST | `/api/v1/users/:id/upload-profile-image-base64` | Sube imagen de perfil (Base64) | Params: id, Body: image (b64), mimeType? | — | Sí | `src/modules/users/user.routes.ts` | OK |
| DELETE | `/api/v1/users/:id/profile-image` | Elimina imagen de perfil | Params: id | — | Sí | `src/modules/users/user.routes.ts` | OK |
| GET | `/api/v1/users/:id/profile-image` | Obtiene URL/path de imagen de perfil | Params: id | — | No** | `src/modules/users/user.routes.ts` | OK |
| POST | `/api/v1/users/fcm-token` | Guarda token FCM (push) | Body: token | — | Sí | `src/modules/users/user.routes.ts` | OK |
| POST | `/api/v1/instructors/register` | Registro de instructor | Body: createInstructorSchema | instructor | No | `src/modules/instructors/instructor.routes.ts` | OK |
| GET | `/api/v1/instructors` | Lista instructores | — | instructores | No | `src/modules/instructors/instructor.routes.ts` | OK |
| GET | `/api/v1/instructors/nearby` | Instructores cercanos (mapa) | Query: lat, lng, radiusKm?, limit? | NearbyInstructorItem[] | No | `src/modules/instructors/instructor.routes.ts` | OK |
| GET | `/api/v1/instructors/me` | Perfil completo del instructor autenticado | — | instructor (full) | Sí (INSTRUCTOR) | `src/modules/instructors/instructor.routes.ts` | OK |
| PUT | `/api/v1/instructors/me` | Actualiza perfil del instructor autenticado | Body: updateInstructorSchema | instructor (full) | Sí (INSTRUCTOR) | `src/modules/instructors/instructor.routes.ts` | OK |
| PATCH | `/api/v1/instructors/me/listed` | Activa/desactiva visibilidad en listado | Body: `{ "isListed": boolean }` | `{ isListed }` | Sí (INSTRUCTOR) | `src/modules/instructors/instructor.routes.ts` | OK |
| GET | `/api/v1/instructors/:id` | Perfil público de instructor (solo si isListed=true) | Params: id | PublicInstructorProfile | No | `src/modules/instructors/instructor.routes.ts` | OK |
| PUT | `/api/v1/instructors/:id` | Actualiza perfil (solo propio; auth + id debe coincidir) | Params: id, Body: updateSchema | instructor | Sí | `src/modules/instructors/instructor.routes.ts` | OK |
| POST | `/api/v1/permissions` | Crea permiso | Body: createPermissionSchema | permission | No** | `src/modules/permissions/permissions.routes.ts` | OK |
| GET | `/api/v1/permissions` | Lista permisos | — | permissions | No** | `src/modules/permissions/permissions.routes.ts` | OK |
| GET | `/api/v1/permissions/:id` | Obtiene permiso por ID | Params: id | permission | No** | `src/modules/permissions/permissions.routes.ts` | OK |
| PUT | `/api/v1/permissions/:id` | Actualiza permiso | Params: id, Body: updateSchema | permission | No** | `src/modules/permissions/permissions.routes.ts` | OK |
| DELETE | `/api/v1/permissions/:id` | Elimina permiso | Params: id | — | No** | `src/modules/permissions/permissions.routes.ts` | OK |
| POST | `/api/v1/cars` | Crea auto | Body: createCarSchema | car | Sí | `src/modules/cars/improved-cars.routes.ts` | OK |
| GET | `/api/v1/cars` | Lista autos (con filtros query) | Query: carFiltersSchema | cars | Sí | `src/modules/cars/improved-cars.routes.ts` | OK |
| GET | `/api/v1/cars/instructor/:instructorId` | Autos de un instructor | Params: instructorId | cars | Sí | `src/modules/cars/improved-cars.routes.ts` | OK |
| GET | `/api/v1/cars/:id` | Auto por ID | Params: id | car | Sí | `src/modules/cars/improved-cars.routes.ts` | OK |
| PUT | `/api/v1/cars/:id` | Actualiza auto | Params: id, Body: updateSchema | car | Sí | `src/modules/cars/improved-cars.routes.ts` | OK |
| PATCH | `/api/v1/cars/:id/toggle-status` | Activa/desactiva auto | Params: id | car | Sí | `src/modules/cars/improved-cars.routes.ts` | OK |
| DELETE | `/api/v1/cars/:id` | Elimina auto | Params: id | — | Sí | `src/modules/cars/improved-cars.routes.ts` | OK |
| GET | `/api/v1/classes` | Lista clases de manejo | — | classes | No** | `src/modules/drivingClass/routes.ts` | OK |
| GET | `/api/v1/classes/:id` | Clase por ID | Params: id | class | No** | `src/modules/drivingClass/routes.ts` | OK |
| POST | `/api/v1/classes` | Crea clase | Body: createDrivingClassSchema | class | No** | `src/modules/drivingClass/routes.ts` | OK |
| PUT | `/api/v1/classes/:id` | Actualiza clase | Params: id, Body: updateSchema | class | No** | `src/modules/drivingClass/routes.ts` | OK |
| PATCH | `/api/v1/classes/:id/cancel` | Cancela clase | Params: id | class | No** | `src/modules/drivingClass/routes.ts` | OK |
| DELETE | `/api/v1/classes/:id` | Elimina clase | Params: id | — | No** | `src/modules/drivingClass/routes.ts` | OK |
| POST | `/api/v1/payments` | Crea pago | Body: createPaymentSchema | payment | Sí | `src/modules/payments/functional-payment.routes.ts` | OK |
| GET | `/api/v1/payments` | Lista pagos | — | payments | Sí | `src/modules/payments/functional-payment.routes.ts` | OK |
| GET | `/api/v1/payments/:id` | Pago por ID | Params: id | payment | Sí | `src/modules/payments/functional-payment.routes.ts` | OK |
| GET | `/api/v1/payments/driving-class/:drivingClassId` | Pagos de una clase | Params: drivingClassId | payments | Sí | `src/modules/payments/functional-payment.routes.ts` | OK |
| PUT | `/api/v1/payments/:id/status` | Actualiza estado del pago | Params: id, Body: status | payment | Sí | `src/modules/payments/functional-payment.routes.ts` | OK |
| POST | `/api/v1/payments/:id/process` | Procesa pago | Params: id | payment | Sí | `src/modules/payments/functional-payment.routes.ts` | OK |
| POST | `/api/v1/payments/booking/:bookingId/preference` | Crea preferencia MP por bookingId (Shortcut) | Params: bookingId | preferenceId, initPoint | Sí (STUDENT) | `src/modules/payments/functional-payment.routes.ts` | OK |
| POST | `/api/v1/payments/mercadopago/preference` | Crea preferencia MP por bookingId (M6) | Body: `{ "bookingId": number }` | preferenceId, initPoint | Sí (STUDENT) | `src/modules/payments/functional-payment.routes.ts` | OK |
| POST | `/api/v1/payments/mercadopago` | Crea pago con MP | Body: createPaymentSchema | payment | Sí | `src/modules/payments/functional-payment.routes.ts` | OK |
| POST | `/api/v1/payments/mercadopago/webhook` | Webhook MP: confirma/cancela booking y actualiza slot (M6) | Body: payload MP | `{ ok: true }` 200 | No | `src/modules/payments/functional-payment.routes.ts` (webhookRouter) | OK |
| POST | `/api/v1/payments/with-commission` | Crea pago con comisión (split) | Body: createPaymentSchema | payment | Sí | `src/modules/payments/commission.routes.ts` | OK |
| GET | `/api/v1/payments/commission-report` | Reporte de comisiones | — | report | Sí (admin recomendado) | `src/modules/payments/commission.routes.ts` | OK |
| GET | `/api/v1/payments/instructor/:instructorId/earnings` | Ganancias de instructor | Params: instructorId | earnings | Sí | `src/modules/payments/commission.routes.ts` | OK |
| POST | `/api/v1/schedule/slots` | Crea slot de horario (sin superposición) | Body: startTime, endTime | slot | Sí (INSTRUCTOR) | `src/modules/schedule/schedule.routes.ts` | OK |
| GET | `/api/v1/schedule/:id` | Slot por ID | Params: id | slot | No | `src/modules/schedule/schedule.routes.ts` | OK |
| GET | `/api/v1/schedule/instructor/:instructorId` | Slots disponibles de instructor | Params: instructorId | slots | No | `src/modules/schedule/schedule.routes.ts` | OK |
| POST | `/api/v1/schedule/reserve/:slotId` | Hold + booking PENDING_PAYMENT (atómico) | Params: slotId | bookingId, slot, heldUntil | Sí (STUDENT) | `src/modules/schedule/schedule.routes.ts` | OK |
| POST | `/api/v1/schedule/cancel/:slotId` | Cancela hold/reserva (slot→AVAILABLE, booking→CANCELLED) | Params: slotId | slot, booking: { status } | Sí | `src/modules/schedule/schedule.routes.ts` | OK |
| DELETE | `/api/v1/schedule/:slotId` | Elimina slot (solo si no BOOKED) | Params: slotId | — | Sí (INSTRUCTOR) | `src/modules/schedule/schedule.routes.ts` | OK |
| POST | `/api/v1/notifications/send-to-user` | Envía notificación a usuario | Body: sendToUserSchema | — | No** | `src/modules/notifications/routes.ts` | OK |
| POST | `/api/v1/notifications/send-to-role` | Envía notificación por rol | Body: sendToRoleSchema | — | No** | `src/modules/notifications/routes.ts` | OK |
| POST | `/api/v1/notifications/broadcast` | Notificación broadcast | Body: broadcastSchema | — | No** | `src/modules/notifications/routes.ts` | OK |
| POST | `/api/v1/notifications/token` | Registra token de push | Body: registerTokenSchema | — | No** | `src/modules/notifications/routes.ts` | OK |
| POST | `/api/v1/messages/send` | Envía mensaje | Body: sendMessageSchema | message | Sí | `src/modules/messages/messages.routes.ts` | OK |
| GET | `/api/v1/messages/conversations` | Conversaciones del usuario | — | conversations | Sí | `src/modules/messages/messages.routes.ts` | OK |
| GET | `/api/v1/messages/conversations/:conversationId/messages` | Mensajes de una conversación | Params: conversationId | messages | Sí | `src/modules/messages/messages.routes.ts` | OK |
| GET | `/api/v1/messages/unread-count` | Cantidad de no leídos | — | count | Sí | `src/modules/messages/messages.routes.ts` | OK |
| PUT | `/api/v1/messages/conversations/:conversationId/read` | Marca conversación como leída | Params: conversationId | — | Sí | `src/modules/messages/messages.routes.ts` | OK |
| GET | `/api/v1/admin/dashboard/stats` | Estadísticas del dashboard | — | stats | Sí (ADMIN) | `src/modules/admin/admin.routes.ts` | OK |
| GET | `/api/v1/admin/system/health` | Salud del sistema (métricas) | — | health | Sí (ADMIN) | `src/modules/admin/admin.routes.ts` | OK |
| PATCH | `/api/v1/admin/users/:userId/manage` | Gestiona usuario (activar/desactivar, etc.) | Params: userId, Body | user | Sí (ADMIN) | `src/modules/admin/admin.routes.ts` | OK |
| GET | `/api/v1/admin/reports/config` | Config de reportes | — | config | Sí (ADMIN) | `src/modules/admin/admin.routes.ts` | OK |
| PUT | `/api/v1/admin/reports/config` | Actualiza config de reportes | Body | config | Sí (ADMIN) | `src/modules/admin/admin.routes.ts` | OK |
| POST | `/api/v1/admin/reports/send-now` | Envía reporte ahora | — | — | Sí (ADMIN) | `src/modules/admin/admin.routes.ts` | OK |

- **Auth:** “Sí” = ruta protegida por middleware de autenticación (JWT). “Sí (ADMIN)” = además requiere rol ADMIN. “No” = pública. “No*” = puede usar cookie/token para blacklist. “No**” = ruta no exige auth en el código actual (revisar si debería).

### Rutas no montadas

- **Payment recovery:** Existe `payment-recovery.controller.ts` y `payment-recovery.service.ts`, pero no hay rutas montadas en `app.ts`. La recuperación de pagos se ejecuta por cron en `SchedulerService`, no por HTTP.

### Nota PRODUCTION-READY vs rutas reales

En `PRODUCTION-READY.md` se mencionan rutas como `POST /api/v1/notifications/register-token` y `POST /api/v1/notifications/test`. En el código las rutas de notificaciones son: `/send-to-user`, `/send-to-role`, `/broadcast`, `/token`. No existe `/register-token` ni `/test`; el equivalente al registro de token es `POST /api/v1/notifications/token`.

---

### M2 — Instructors: /me y perfil público (Flutter)

Base: `BASE=http://localhost:3000/api/v1`. Reemplazar `INSTRUCTOR_TOKEN` y `STUDENT_TOKEN` por tokens JWT válidos.

#### GET /api/v1/instructors/me
- **Auth:** Bearer token, rol INSTRUCTOR.
- **Request:** Sin body.
- **Response 200:** Perfil completo del instructor (incl. user, permissions, cars, bio, categories, photos, isListed, lat, lng, addressText, hourlyRate, etc.).
- **401:** No autenticado / token inválido.
- **403:** Rol distinto de INSTRUCTOR (ej. STUDENT).
- **404:** Usuario no tiene perfil de instructor.

```bash
curl -s -H "Authorization: Bearer INSTRUCTOR_TOKEN" "$BASE/instructors/me"
```

#### PUT /api/v1/instructors/me
- **Auth:** Bearer token, rol INSTRUCTOR.
- **Request body (ejemplo):** `{ "bio": "Texto...", "categories": ["ruta","ciudad"], "photos": ["https://..."], "isListed": true, "lat": -34.6, "lng": -58.4, "addressText": "Av. X 123", "hourlyRate": 50000 }` (todos los campos opcionales; validación vía updateInstructorSchema).
- **Response 200:** Perfil completo actualizado.
- **401/403/404:** Igual que GET /me. **422:** Validación fallida (campos inválidos).

```bash
curl -s -X PUT -H "Authorization: Bearer INSTRUCTOR_TOKEN" -H "Content-Type: application/json" \
  -d '{"bio":"Instructor con experiencia","categories":["ruta"],"photos":[],"isListed":true,"lat":-34.6,"lng":-58.4,"addressText":"CABA","hourlyRate":50000}' \
  "$BASE/instructors/me"
```

#### PATCH /api/v1/instructors/me/listed
- **Auth:** Bearer token, rol INSTRUCTOR.
- **Request body:** `{ "isListed": true }` o `{ "isListed": false }` (boolean obligatorio).
- **Response 200:** `{ "isListed": true }` o `{ "isListed": false }`.
- **401/403/404:** Igual que GET /me. **422:** Body inválido (falta isListed o no es boolean).

```bash
curl -s -X PATCH -H "Authorization: Bearer INSTRUCTOR_TOKEN" -H "Content-Type: application/json" \
  -d '{"isListed":true}' "$BASE/instructors/me/listed"
```

#### GET /api/v1/instructors/:id (perfil público)
- **Auth:** No requerida.
- **Response 200:** Objeto público: `id`, `displayName`, `bio`, `categories`, `photos`, `hourlyRate`, `isListed`, `lat`, `lng`. No expone email ni datos sensibles.
- **404:** Instructor no existe o `isListed=false` (no visible en listado).

```bash
curl -s "$BASE/instructors/1"
```

#### PUT /api/v1/instructors/:id
- **Auth:** Bearer token. Solo puede editar el perfil cuyo `id` coincide con el instructor del usuario autenticado.
- **403:** Token de otro usuario o no instructor (no puede editar ese id). **422:** ID inválido.

---

#### Criterios de aceptación (curl)

1. **Como instructor:**  
   `GET /instructors/me` → 200 y perfil; `PUT /instructors/me` con bio/categories/photos/location → 200; `PATCH /instructors/me/listed` con `{"isListed":true}` o `false` → 200 y `{ "isListed": ... }`.

2. **Como estudiante:**  
   `GET /instructors/me` → 403; `PUT /instructors/me` → 403; `PATCH /instructors/me/listed` → 403.

3. **Público:**  
   `GET /instructors/:id` con instructor existente y `isListed=true` → 200 y perfil público; con `isListed=false` o id inexistente → 404.

---

### M3 — Instructors: nearby (mapa, búsqueda por ubicación)

- **Endpoint:** `GET /api/v1/instructors/nearby`
- **Auth:** No (público).
- **Query params:**
  - `lat` (required): número, -90..90.
  - `lng` (required): número, -180..180.
  - `radiusKm` (optional): número, default 5, min 0.5, max 50.
  - `limit` (optional): entero, default 50, min 1, max 200.
- **Response 200:** Array de objetos `NearbyInstructorItem`: `id`, `displayName`, `bio`, `categories`, `photos`, `hourlyRate`, `lat`, `lng`, `distanceKm` (float 2 decimales). Solo instructores con `isListed=true` y `lat`/`lng` no nulos; ordenados por distancia ascendente; limitados por `limit`.
- **422:** Parámetros inválidos (lat/lng fuera de rango, radiusKm/limit fuera de rango, o lat/lng faltantes).

**Request example:**
```
GET /api/v1/instructors/nearby?lat=-34.6037&lng=-58.3816&radiusKm=10&limit=20
```

**Response example:**
```json
[
  {
    "id": 1,
    "displayName": "Juan Pérez",
    "bio": "Instructor con experiencia en ruta.",
    "categories": ["ruta", "ciudad"],
    "photos": ["https://..."],
    "hourlyRate": 50000,
    "lat": -34.604,
    "lng": -58.382,
    "distanceKm": 0.15
  }
]
```

**curl:**
```bash
curl -s "http://localhost:3000/api/v1/instructors/nearby?lat=-34.6037&lng=-58.3816&radiusKm=5&limit=50"
```

**Invalid params (422):**
```bash
curl -s "http://localhost:3000/api/v1/instructors/nearby?lat=95&lng=0"   # lat fuera de rango
curl -s "http://localhost:3000/api/v1/instructors/nearby?lng=-58"       # falta lat
```

---

### M4+M5 — Schedule: slot state machine, hold, reserve, cancel, cleanup

- **SlotStatus:** AVAILABLE, HELD, BOOKED, BLOCKED.
- **Hold:** 10 minutos (`heldUntil = now + 10 min`). Job cada 2 min libera HELD vencidos y cancela booking PENDING_PAYMENT.
- **Reserve:** atómico (hold slot + crear DrivingClass PENDING_PAYMENT + crear Payment pending/mercadopago + vincular slot.drivingClassId). Si falla cualquier paso, rollback completo. Solo STUDENT.
- **Create slot:** solo INSTRUCTOR; `instructorId` del usuario autenticado; body solo `startTime`, `endTime`. 409 si hay superposición con otro slot del mismo instructor.

#### 1) Instructor crea slot → status AVAILABLE

- **Auth:** Bearer, rol INSTRUCTOR.
- **Body:** `{ "startTime": "<ISO>", "endTime": "<ISO>" }` (fin > inicio).
- **Response 201:** slot con `status: "AVAILABLE"`, `heldUntil: null`.
- **409:** Superposición con otro slot del mismo instructor.

```bash
# Reemplazar INSTRUCTOR_TOKEN por JWT de un usuario con rol INSTRUCTOR
curl -s -X POST -H "Authorization: Bearer INSTRUCTOR_TOKEN" -H "Content-Type: application/json" \
  -d '{"startTime":"2025-03-01T10:00:00.000Z","endTime":"2025-03-01T11:00:00.000Z"}' \
  "http://localhost:3000/api/v1/schedule/slots"
```

#### 2) Estudiante reserva → slot HELD, heldUntil ~10 min, booking PENDING_PAYMENT

- **Auth:** Bearer, rol STUDENT.
- **Params:** slotId.
- **Response 201:** `{ "bookingId": number, "slot": { id, status: "HELD", heldUntil, ... }, "heldUntil": "<ISO>" }`.
- **409:** Slot no disponible (ya HELD no vencido o BOOKED).

```bash
# Reemplazar STUDENT_TOKEN y SLOT_ID
curl -s -X POST -H "Authorization: Bearer STUDENT_TOKEN" \
  "http://localhost:3000/api/v1/schedule/reserve/SLOT_ID"
```

#### 3) Segundo estudiante reserva el mismo slot → 409

- Mismo `POST /schedule/reserve/:slotId` con otro STUDENT_TOKEN (o el mismo). Debe devolver 409 si el slot ya está HELD (no vencido) o BOOKED.

```bash
curl -s -X POST -H "Authorization: Bearer OTHER_STUDENT_TOKEN" \
  "http://localhost:3000/api/v1/schedule/reserve/SLOT_ID"
# Esperado: 409
```

#### 4) Cleanup job: tras expirar heldUntil, slot vuelve a AVAILABLE y booking PENDING_PAYMENT → CANCELLED

- El job corre cada 2 min en `SchedulerService` (`scheduleHoldExpiryCleanup`). No hay endpoint; es automático.
- Para probar: poner en DB `held_until` en el pasado para un slot HELD y esperar 2 min (o ejecutar manualmente la lógica en un script). Tras el job: slot `status=AVAILABLE`, `held_until=null`, `driving_class_id=null`; DrivingClass asociada `status=CANCELLED` si estaba PENDING_PAYMENT.

#### 5) Cancel (solo slots HELD; estudiante o instructor dueño)

- **Auth:** Bearer (STUDENT dueño del booking o INSTRUCTOR dueño del slot).
- **Params:** slotId.
- **Comportamiento:** Solo se puede cancelar un slot en estado **HELD** (hold con booking PENDING_PAYMENT). Si el slot está **BOOKED** (pago confirmado), se responde **409** con mensaje claro; en ese caso usar flujo de cancelación de clase si aplica.
- **Response 200 (cancelación efectiva):** `{ "slot": { ..., status: "AVAILABLE", heldUntil: null }, "booking": { "status": "CANCELLED" } }`.
- **Response 200 (idempotente):** Si el slot ya está AVAILABLE o el booking ya estaba CANCELLED, se devuelve 200 con el estado actual y opcionalmente `"message": "Slot ya estaba disponible (idempotente)."` o `"Booking ya estaba cancelado (idempotente)."`.
- **409:** Slot en estado BOOKED o BLOCKED (no se puede cancelar por este endpoint).

```bash
curl -s -X POST -H "Authorization: Bearer STUDENT_TOKEN" \
  "http://localhost:3000/api/v1/schedule/cancel/SLOT_ID"
```

#### 6) Delete slot (solo INSTRUCTOR, slot no BOOKED)

- **Auth:** Bearer, rol INSTRUCTOR. Solo puede borrar slots propios.
- **409:** Si el slot está BOOKED.
- **Response 204:** sin body.

```bash
curl -s -X DELETE -H "Authorization: Bearer INSTRUCTOR_TOKEN" \
  "http://localhost:3000/api/v1/schedule/SLOT_ID"
```

#### Criterios de aceptación (resumen)

1. Instructor crea slot → 201, slot con status AVAILABLE.
2. Estudiante reserva → 201, slot HELD con heldUntil ~10 min, booking PENDING_PAYMENT creado; respuesta con bookingId, slot, heldUntil.
3. Segundo estudiante reserva mismo slot → 409.
4. Tras expirar heldUntil (o forzar en DB), el job de cleanup libera slot y cancela booking PENDING_PAYMENT.
5. Cancel endpoint libera slot y cancela booking.
6. `npm run build` pasa.

---

### M6 — MercadoPago: preferencia por booking y webhook

#### POST /api/v1/payments/mercadopago/preference (crear preferencia por reserva)

- **Auth:** Bearer, rol **STUDENT**. Solo el estudiante dueño de la reserva puede crear la preferencia.
- **Body:** `{ "bookingId": number }` (bookingId = id de DrivingClass / reserva).
- **Validación:** La reserva existe, pertenece al usuario, `status === PENDING_PAYMENT`; existe slot vinculado con `status === HELD` y `heldUntil > now`; existe Payment con `provider === "mercadopago"` y `status === "pending"`. Si el hold expiró → **409** indicando re-reservar.
- **Respuesta 201:** `{ "data": { "preferenceId": string, "initPoint": string }, "success": true, ... }` (o el formato que use `ResponseFormatter.created`). En Payment se persiste `preferenceId` y `externalReference = bookingId`.
- **Errores:** **401** no autenticado; **403** no es STUDENT o no es dueño de la reserva; **404** reserva/slot/pago no encontrado; **409** reserva no pendiente, slot no HELD, hold expirado o pago no pendiente.

**Request:**
```bash
curl -s -X POST -H "Authorization: Bearer STUDENT_TOKEN" -H "Content-Type: application/json" \
  -d '{"bookingId": 123}' \
  "http://localhost:3000/api/v1/payments/mercadopago/preference"
```

**Response 201 (ejemplo):**
```json
{
  "success": true,
  "data": { "preferenceId": "abc-123", "initPoint": "https://www.mercadopago.com.ar/checkout/v1/redirect?pref_id=abc-123" },
  "message": "Preferencia creada"
}
```

#### POST /api/v1/payments/mercadopago/webhook

- **Auth:** No (público; lo llama MercadoPago).
- **Body:** Payload de Mercado Pago (ej. `{ type: "payment", data: { id: string } }`). Se guarda en Payment como `rawPayload`.
- **Comportamiento (idempotente):** Se obtiene el pago de MP por `data.id`, se lee `external_reference` (= bookingId). Se actualiza el Payment (status normalizado: approved / rejected / pending, paymentId, rawPayload). En una sola transacción Prisma:
  - **Si payment approved:** booking.status → CONFIRMED (si no lo estaba), slot.status → BOOKED, heldUntil → null.
  - **Si payment rejected/cancelled/refunded/charged_back:** booking.status → CANCELLED (si no lo estaba), slot → AVAILABLE, heldUntil null, drivingClassId null.
- **Respuesta:** Siempre **200** con `{ "ok": true }` para cortar reintentos de MP.

**Payload típico (alto nivel):**
```json
{ "type": "payment", "data": { "id": "123456789" } }
```

**Simular webhook aprobado (tras obtener payment id de MP):** el backend llama a la API de MP para obtener el pago y aplica la lógica según `status`. En pruebas con sandbox se puede llamar al webhook con el payload que envía MP.

**Curl de ejemplo (simular notificación; el id es el de MP):**
```bash
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"type":"payment","data":{"id":"123456789"}}' \
  "http://localhost:3000/api/v1/payments/mercadopago/webhook"
```

#### Criterios de aceptación M6

1. Reservar slot → booking PENDING_PAYMENT, slot HELD, payment pending.
2. Crear preferencia (STUDENT, bookingId) → 201 con preferenceId e initPoint; Payment tiene preferenceId guardado.
3. Webhook approved (sandbox o simulado) → booking CONFIRMED, slot BOOKED.
4. Webhook rejected → booking CANCELLED, slot AVAILABLE.
5. Webhook llamado dos veces → idempotente, mismo estado final.
6. `npm run build` pasa.
