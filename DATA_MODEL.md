# DATA_MODEL — Modelo de datos

## Dónde se define

- **ORM / schema:** `prisma/schema.prisma` — define tablas, campos, relaciones y enums.
- **Migraciones versionadas:** `prisma/migrations/` — SQL aplicado por `prisma migrate deploy`.
- **Scripts SQL manuales:** `sql/` — tablas que no están en el schema de Prisma o se crean aparte (logs, blacklisted_tokens, payment_recovery si se usan scripts legacy).

---

## Tablas / entidades (Prisma)

### User

- **Qué es:** Usuario del sistema (estudiante, instructor o admin).
- **Campos principales:** id, name, surname, email (único), password, dni (único), birthDate, isActive, role (STUDENT | INSTRUCTOR | ADMIN), lastLoginAt, emailVerificationToken, emailVerifiedAt, emailNotifications, pushNotifications, profileImage, createdAt.
- **Relaciones:** Admin (1:1), Instructor (1:1), Student (1:1), NotificationToken (1:1), Session (1:N), Message (1:N), Conversation (N:N con User vía participant1/participant2).

### Session

- **Qué es:** Sesión de usuario (refresh token) para mantener la sesión abierta.
- **Campos:** id (UUID), userId, refreshHash (único), userAgent, ip, createdAt, expiresAt, revokedAt.
- **Relación:** Pertenece a un User.

### Student

- **Qué es:** Rol “estudiante”; vincula User con clases de manejo.
- **Campos:** id, userId (único).
- **Relaciones:** User (1:1), DrivingClass (1:N).

### Instructor

- **Qué es:** Rol “instructor”; tiene vehículos, slots y clases.
- **Campos:** id, userId (único), licenseNumber, experienceYears, available, isValid, mpCollectorId, mpAccessToken, commissionRate (ej. 80).
- **Relaciones:** User (1:1), Car (1:N), DrivingClass (1:N), InstructorPermission (N:N con Permission), ScheduleSlot (1:N).

### Admin

- **Qué es:** Rol “administrador”; una fila por usuario admin.
- **Campos:** id (mismo que User.id), companyName.
- **Relación:** User (1:1).

### Car

- **Qué es:** Vehículo de un instructor.
- **Campos:** id, brand, model, year, licensePlate (único), transmission (MANUAL | AUTOMATIC), isActive, instructorId, createdAt, updatedAt.
- **Relación:** Instructor (N:1).

### Permission

- **Qué es:** Permiso que puede tener un instructor (ej. categoría de licencia).
- **Campos:** id, name, description, isMandatory.
- **Relaciones:** InstructorPermission (N:N con Instructor).

### InstructorPermission

- **Qué es:** Tabla intermedia: qué permiso tiene cada instructor y si está concedido.
- **Campos:** instructorId, permissionId, granted.
- **Relación:** Instructor (N:1), Permission (N:1).

### DrivingClass

- **Qué es:** Una clase de manejo (estudiante + instructor + fecha/duración).
- **Campos:** id, date, duration, status (ej. "scheduled"), notes, studentId, instructorId, createdAt, updatedAt.
- **Relaciones:** Student (N:1), Instructor (N:1), Payment (1:N), ScheduleSlot (0..1).

### Payment

- **Qué es:** Pago asociado a una clase (efectivo, tarjeta, transfer, Mercado Pago).
- **Campos:** id, amount, status, paymentMethod, drivingClassId, externalReference, paymentId, preferenceId, idempotencyKey, lastRecoveryAt, recoveryAttempts, appCommission, instructorAmount, commissionRate, createdAt, updatedAt.
- **Relación:** DrivingClass (N:1).

### ScheduleSlot

- **Qué es:** Franja horaria que un instructor ofrece; puede estar reservada por una clase.
- **Campos:** id (CUID), instructorId, startTime, endTime, isBooked, drivingClassId (opcional, único), createdAt, updatedAt.
- **Relaciones:** Instructor (N:1), DrivingClass (0..1).

### NotificationToken

- **Qué es:** Token FCM (Firebase) para enviar push a un usuario.
- **Campos:** id, userId (único), token (único), createdAt, updatedAt.
- **Relación:** User (1:1).

### PaymentRecoveryLog

- **Qué es:** Log de intentos de recuperación de pagos (cron).
- **Campos:** id, paymentId, step, status, data, error, timestamp.
- **Tabla en DB:** `payment_recovery_logs` (`@@map` en schema).

### BlacklistedToken

- **Qué es:** JWT invalidados (logout) para no aceptar el mismo token otra vez.
- **Campos:** id, jti (único), expiresAt, createdAt.
- **Tabla en DB:** `blacklisted_tokens` (`@@map` en schema).

### Conversation

- **Qué es:** Conversación entre dos usuarios (mensajería).
- **Campos:** id, participant1Id, participant2Id, createdAt, updatedAt. Restricción única (participant1Id, participant2Id).
- **Relaciones:** User (2x N:1), Message (1:N).

### Message

- **Qué es:** Un mensaje dentro de una conversación.
- **Campos:** id, conversationId, senderId, content, sentAt, readAt.
- **Relaciones:** Conversation (N:1), User (N:1).

### SystemConfig

- **Qué es:** Configuración global del sistema (reportes, alertas).
- **Campos:** id, reportInterval (daily/weekly/monthly), reportEmails (JSON string), errorAlertsEnabled, lastReportSent, createdAt, updatedAt.

### Enums

- **Role:** STUDENT, INSTRUCTOR, ADMIN.
- **Transmission:** MANUAL, AUTOMATIC.

---

## Tablas fuera de Prisma (SQL manual)

- **logs:** Definida en `sql/create_logs_table.sql`. Usada por el sistema de logging (DatabaseTransport). No hay modelo en `schema.prisma`. Se crea ejecutando ese script o `scripts/setup-logging.js`.
- **blacklisted_tokens:** También existe como modelo Prisma (`BlacklistedToken` con `@@map("blacklisted_tokens")`). Si usas solo Prisma, la migración o `db push` crea la tabla. Los scripts en `sql/create_blacklisted_tokens_table.sql` son alternativa manual.
- **payment_recovery_logs:** Modelo en Prisma (`PaymentRecoveryLog` con `@@map("payment_recovery_logs")`). Misma idea: Prisma puede crearla; si hay scripts SQL legacy, pueden ser redundantes.

---

## Estado de migraciones y seeds

- **Migraciones Prisma:** Hay 8 migraciones en `prisma/migrations/` (desde refresh_hash_is_unique hasta creación de ScheduleSlot y NotificationToken). No hay migración explícita que cree `BlacklistedToken` ni `PaymentRecoveryLog` en esa carpeta; si están en el schema actual, se crean al ejecutar `npx prisma db push` (o al generar una nueva migración).
- **Seeds:** No hay carpeta `prisma/seed.ts` ni script `prisma db seed` en `package.json`. No hay seeds oficiales en el repo.
- **Scripts de setup:** `scripts/setup-logging.js`, `scripts/setup-blacklisted-tokens.js`, `scripts/setup-payment-recovery.js`, etc., crean o preparan tablas/estructuras adicionales (logs, blacklisted_tokens, payment_recovery) según corresponda.

**Qué falta para dejar la DB lista:**

1. Alinear forma de crear tablas: o todo vía Prisma (migraciones o `db push`) o documentar qué scripts SQL ejecutar y en qué orden.
2. Añadir migración para `BlacklistedToken` y `PaymentRecoveryLog` si no se usa `db push`, para que `prisma migrate deploy` deje la DB consistente.
3. Crear tabla `logs` (script o migración raw) si se usa logging a base de datos.
4. (Opcional) Añadir seed para datos iniciales (ej. permisos, usuario admin) y documentar en RUNBOOK.
