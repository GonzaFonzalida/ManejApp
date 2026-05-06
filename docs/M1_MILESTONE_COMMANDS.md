# M1 — Comandos y pruebas

## Comandos exactos para correr

```bash
# 1. Instalar dependencias (si hace falta)
npm install

# 2. Aplicar migración M1 (elegir una opción)

# Opción A: Si la base está al día con el historial de migraciones
npx prisma migrate deploy

# Opción B: Si hay drift o la base ya existía sin migraciones
# Aplicar el SQL a mano contra tu Postgres:
psql "$DATABASE_URL" -f prisma/migrations/20250203000000_m1_mvp_schema/migration.sql

# 3. Regenerar cliente Prisma (tras aplicar migración)
npx prisma generate

# 4. Compilar
npm run build

# 5. Levantar servidor
npm run dev
# o
npm start
```

## Endpoints para testear con curl

Base URL de ejemplo: `http://localhost:3000/api/v1`. Reemplazá `BASE` en los ejemplos.

### 1. Config (público)

```bash
curl -s http://localhost:3000/api/v1/config
```

### 2. Auth — Login (obtener token para rutas protegidas)

```bash
# Respuesta incluye token para usar en Authorization: Bearer <token>
curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"tu@email.com","password":"tu_password"}'
```

### 3. Instructors — Listar

```bash
curl -s http://localhost:3000/api/v1/instructors
```

### 4. Instructors — Ver perfil por ID

```bash
curl -s http://localhost:3000/api/v1/instructors/1
```

### 5. Instructors — Actualizar perfil (nuevos campos M1)

Requiere auth de instructor (o según tu middleware). Reemplazá `TOKEN` e `INSTRUCTOR_ID`.

```bash
curl -s -X PUT "http://localhost:3000/api/v1/instructors/INSTRUCTOR_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "bio": "Instructor con experiencia en ruta y ciudad.",
    "categories": ["ruta", "ciudad"],
    "photos": ["https://example.com/foto1.jpg"],
    "isListed": true,
    "lat": -34.6037,
    "lng": -58.3816,
    "addressText": "Av. Corrientes 1234, CABA",
    "hourlyRate": 50000
  }'
```

### 6. Schedule — Slots de un instructor

```bash
curl -s "http://localhost:3000/api/v1/schedule/instructor/1"
```

### 7. Schedule — Crear slot (auth instructor)

Los slots se crean con `status: AVAILABLE` (M1).

```bash
curl -s -X POST "http://localhost:3000/api/v1/schedule/slots" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "instructorId": 1,
    "startTime": "2025-02-10T10:00:00.000Z",
    "endTime": "2025-02-10T11:00:00.000Z"
  }'
```

### 8. Schedule — Reservar slot (auth student)

Crea DrivingClass con `status: PENDING_PAYMENT` y marca el slot como reservado (`status: BOOKED`).

```bash
curl -s -X POST "http://localhost:3000/api/v1/schedule/reserve/SLOT_ID" \
  -H "Authorization: Bearer TOKEN"
```

### 9. Classes — Listar clases

```bash
curl -s http://localhost:3000/api/v1/classes
```

### 10. Classes — Ver una clase

```bash
curl -s http://localhost:3000/api/v1/classes/1
```

### 11. Payments — Preferencia Mercado Pago

```bash
curl -s -X POST "http://localhost:3000/api/v1/payments/mercadopago/preference" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "amount": 50000,
    "drivingClassId": 1,
    "description": "Clase de manejo 1h"
  }'
```

---

## Verificación rápida post-M1

- **Instructor**: `GET /api/v1/instructors/1` debe poder devolver `bio`, `categories`, `photos`, `isListed`, `lat`, `lng`, `addressText` (si están cargados).
- **Slot**: `GET /api/v1/schedule/instructor/1` debe mostrar slots con `status` (`AVAILABLE`, `HELD`, `BOOKED`, `BLOCKED`) y opcionalmente `heldUntil`.
- **Clase**: `GET /api/v1/classes/:id` debe mostrar `status` como uno de `PENDING_PAYMENT`, `CONFIRMED`, `CANCELLED`, `COMPLETED` y opcionalmente `amount`, `currency`.
- **Pago**: Crear preferencia y revisar que el registro de pago pueda tener `provider` y `preferenceId` (y opcionalmente `rawPayload` tras webhook).
