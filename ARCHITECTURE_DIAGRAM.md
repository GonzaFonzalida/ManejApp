# ARCHITECTURE_DIAGRAM — Diagrama de arquitectura (texto)

Diagrama en texto (ASCII) de los componentes y cómo se conectan.

---

## Vista general: Cliente → Servidor → Base de datos

```
                    +------------------+
                    |  Cliente (App    |
                    |  móvil / Web)    |
                    +--------+---------+
                             |
                             | HTTP (JSON)
                             v
    +------------------------------------------------------------------------+
    |                         EXPRESS APP (src/app.ts)                        |
    |  +----------------+  +----------------+  +-----------------------------+|
    |  | Helmet, CORS,   |  | Rate limit,   |  | express.json(),             ||
    |  | sanitize, XSS   |  | SQL injection |  | request/error loggers        ||
    |  +----------------+  +----------------+  +-----------------------------+|
    |                                                                         |
    |  Rutas montadas en /api/v1/*:                                           |
    |  /users, /instructors, /permissions, /cars, /auth, /classes,             |
    |  /payments, /schedule, /notifications, /messages, /admin                 |
    +------------------------------------------------------------------------+
                             |
         +-------------------+-------------------+
         |                   |                   |
         v                   v                   v
    +---------+        +------------+      +------------------+
    | Router  |        | Controller  |      | Middlewares       |
    | (*.routes)       | (*.controller)    | (auth, validate)  |
    +----+----+        +------+------+      +------------------+
         |                    |
         |                    v
         |             +------------+
         |             | Service    |
         |             | (*.services)|
         |             +------+-----+
         |                    |
         |                    v
         |             +------------+      +------------------+
         |             | Repository      | DiContainer      |
         |             | (Prisma*)       | (container.ts)   |
         |             +------+-----+     | inyecta deps     |
         |                    |          +------------------+
         |                    v
         |             +------------+
         |             | Prisma     |
         |             | Client     |
         |             +------+------+
         |                    |
         v                    v
    +----------------------------------------+
    |           PostgreSQL (DATABASE_URL)    |
    |  User, Session, Student, Instructor,   |
    |  Admin, Car, Permission, DrivingClass,  |
    |  Payment, ScheduleSlot, Message,       |
    |  Conversation, NotificationToken,     |
    |  BlacklistedToken, PaymentRecoveryLog, |
    |  SystemConfig                          |
    +----------------------------------------+
```

---

## Flujo de una request típica (ej. login)

```
  Cliente                    Express                      Módulo Auth
     |                          |                              |
     |  POST /api/v1/auth/login  |                              |
     |  Body: { email, password }|                              |
     |------------------------->|                              |
     |                          |  authRateLimit               |
     |                          |  validate(loginSchema)       |
     |                          |------------------------------>
     |                          |                              |
     |                          |                    auth.controller.login
     |                          |                    auth.service.login
     |                          |                    UserRepository (Prisma)
     |                          |                              |
     |                          |                    DB: find user by email
     |                          |                    compare password, create session
     |                          |                    generate JWT
     |                          |<------------------------------
     |  JSON { token, user }    |                              |
     |<-------------------------|                              |
```

---

## Integraciones externas

```
    +------------------+
    | ManejApp Backend |
    +--------+---------+
             |
             | DATABASE_URL
             v
    +------------------+
    | PostgreSQL       |
    +------------------+

             | MERCADOPAGO_ACCESS_TOKEN, webhook
             v
    +------------------+
    | Mercado Pago API  |  (pagos, preferencias, webhook)
    +------------------+

             | FIREBASE_SERVICE_ACCOUNT_KEY
             v
    +------------------+
    | Firebase (FCM)   |  (notificaciones push)
    +------------------+

             | EMAIL_* (SMTP)
             v
    +------------------+
    | Servidor SMTP    |  (verificación email, reportes, alertas)
    +------------------+
```

---

## Inyección de dependencias (DiContainer)

```
    container.ts registra:

    Repositorios:  UserRepository, PrismaInstructorRepository, PrismaSessionRepository,
                   PrismaPermissionRepository, PrismaDrivingClassRepository,
                   PrismaPaymentRepository, PrismaScheduleSlotRepository,
                   PrismaNotificationTokenRepository, PrismaMessageRepository

    Servicios:     userService, instructorService, authService, DrivingClassService,
                   paymentService, CommissionEnhancedService, scheduleService,
                   notificationService, messageService, emailService

    Controllers:   userController, instructorController, authController,
                   DrivingClassController, scheduleController, notificationController,
                   messageController

    app.ts resuelve los controllers desde el container y los pasa a los routers.
```

---

## Tareas en background (SchedulerService)

```
    SchedulerService (src/shared/services/SchedulerService.ts)
             |
             +-- paymentRecovery  (cron, ej. cada 30 min)
             |       -> PaymentRecoveryService
             |
             +-- cleanup  (cron, ej. diario 02:00)
             |       -> limpia tokens expirados, logs antiguos, etc.
             |
             +-- classReminders  (cron, ej. diario 20:00)
                     -> recordatorios de clase
```

---

*Documento generado a partir del análisis del codebase (branch backend-MG-01).*
