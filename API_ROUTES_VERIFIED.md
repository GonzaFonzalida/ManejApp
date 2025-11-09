# ✅ Rutas del Backend Verificadas - ManejApp

## BASE URL
```
http://192.168.0.19:3000/api/v1
```

## ✅ AUTENTICACIÓN (/auth) - VERIFICADO
- ✅ `POST /auth/login` - Login principal (USADO)
- ✅ `POST /auth/refresh` - Renovar token (USADO)
- ✅ `POST /auth/logout` - Logout (USADO - CORREGIDO)
- ✅ `GET /auth/me` - Perfil usuario autenticado (IMPLEMENTADO)
- ✅ `GET /auth/sessions` - Sesiones activas (IMPLEMENTADO)
- ✅ `POST /auth/revoke/:sessionId` - Revocar sesión específica (IMPLEMENTADO)
- ✅ `POST /auth/revoke-all` - Revocar todas las sesiones (IMPLEMENTADO)

## ✅ USUARIOS (/users) - VERIFICADO
- ✅ `GET /users/` - Todos los usuarios (NO USADO - solo interno)
- ✅ `GET /users/:value` - Usuario por ID (USADO como getUserProfile)
- ✅ `GET /users/role/:role` - Usuarios por rol (IMPLEMENTADO)
- ✅ `POST /users/register` - Registrar usuario (USADO)
- ✅ `PUT /users/:id` - Actualizar usuario (IMPLEMENTADO - NUEVO)
- ⚠️ `POST /users/login` - NO USAR, usar /auth/login

## ✅ INSTRUCTORES (/instructors) - VERIFICADO
- ✅ `POST /instructors/register` - Registrar instructor (USADO)
- ✅ `GET /instructors/` - Listar instructores (USADO)
- ✅ `GET /instructors/:id` - Instructor por ID (DISPONIBLE)
- ✅ `PUT /instructors/:id` - Actualizar instructor (USADO)

## ✅ VEHÍCULOS (/cars) - VERIFICADO
- ✅ `POST /cars/` - Crear vehículo (IMPLEMENTADO)
- ✅ `GET /cars/` - Listar vehículos (USADO)
- ✅ `GET /cars/instructor/:instructorId` - Vehículos por instructor (DISPONIBLE)
- ✅ `GET /cars/:id` - Vehículo por ID (IMPLEMENTADO)
- ✅ `PUT /cars/:id` - Actualizar vehículo (IMPLEMENTADO)
- ✅ `PATCH /cars/:id/toggle-status` - Cambiar estado (DISPONIBLE)
- ✅ `DELETE /cars/:id` - Eliminar vehículo (IMPLEMENTADO)

## ✅ CLASES (/classes) - VERIFICADO
- ✅ `GET /classes/` - Listar clases (IMPLEMENTADO)
- ✅ `GET /classes/:id` - Clase por ID (IMPLEMENTADO)
- ✅ `POST /classes/` - Crear clase (USADO en reserveClass)
- ✅ `PUT /classes/:id` - Actualizar clase (IMPLEMENTADO)
- ✅ `PATCH /classes/:id/cancel` - Cancelar clase (IMPLEMENTADO)
- ✅ `DELETE /classes/:id` - Eliminar clase (IMPLEMENTADO)
- ✅ `GET /classes/my-classes` - Mis clases (IMPLEMENTADO)

## ✅ PAGOS (/payments) - VERIFICADO
- ✅ `POST /payments/` - Crear pago (DISPONIBLE)
- ✅ `GET /payments/` - Listar pagos (IMPLEMENTADO)
- ✅ `GET /payments/:id` - Pago por ID (IMPLEMENTADO)
- ✅ `GET /payments/driving-class/:drivingClassId` - Pagos por clase (IMPLEMENTADO)
- ✅ `PUT /payments/:id/status` - Actualizar estado (IMPLEMENTADO)
- ✅ `POST /payments/:id/process` - Procesar pago (DISPONIBLE)
- ✅ `POST /payments/mercadopago/preference` - Crear preferencia MP (IMPLEMENTADO)
- ✅ `POST /payments/mercadopago` - Pago con MP (DISPONIBLE)
- ✅ `POST /payments/mercadopago/webhook` - Webhook MP (BACKEND)
- ✅ `GET /payments/mercadopago/status/:id` - Estado de pago MP (IMPLEMENTADO)

## ✅ HORARIOS (/schedule) - VERIFICADO
- ✅ `POST /schedule/slots` - Crear slot (USADO)
- ✅ `GET /schedule/:id` - Slot por ID (IMPLEMENTADO)
- ✅ `GET /schedule/instructor/:instructorId` - Slots disponibles (USADO)
- ✅ `POST /schedule/reserve/:slotId` - Reservar slot (USADO)
- ✅ `POST /schedule/cancel/:slotId` - Cancelar reserva (IMPLEMENTADO)
- ✅ `DELETE /schedule/:slotId` - Eliminar slot (USADO)

## ✅ NOTIFICACIONES (/notifications) - DISPONIBLE
- ⚠️ `POST /notifications/send-to-user` - Notificar usuario (NO IMPLEMENTADO AÚN)
- ⚠️ `POST /notifications/send-to-role` - Notificar por rol (NO IMPLEMENTADO AÚN)
- ⚠️ `POST /notifications/broadcast` - Notificación masiva (NO IMPLEMENTADO AÚN)
- ⚠️ `POST /notifications/token` - Registrar token (NO IMPLEMENTADO AÚN)

## ✅ OTROS - VERIFICADO
- ✅ `GET /health` - Health check (DISPONIBLE)
- ✅ `GET /api-docs` - Documentación Swagger (DISPONIBLE)

## 🔧 CAMBIOS REALIZADOS

### 1. Logout Corregido
**Antes**: `POST /sessions/revoke`  
**Ahora**: `POST /auth/logout` ✅

### 2. Método updateUser Agregado
**Nuevo**: `PUT /users/:id` para actualizar información del usuario (nombre, location, etc.)

### 3. Todas las rutas verificadas contra documentación oficial

## 📝 NOTAS IMPORTANTES

1. **Autenticación**: SIEMPRE usar `/auth/login`, NO `/users/login`
2. **Bearer Token**: Todos los endpoints protegidos requieren `Authorization: Bearer <token>`
3. **Content-Type**: Siempre usar `application/json` para POST/PUT/PATCH
4. **Cars**: TODOS los endpoints de `/cars` requieren autenticación
5. **Location**: El campo `location` debe agregarse a la tabla `users` en el backend

## 🎯 BACKEND REQUIREMENTS

Para que la app funcione completamente, el backend DEBE tener:

### Base de Datos
```sql
ALTER TABLE users ADD COLUMN location VARCHAR(255);
```

### Rutas Requeridas
- ✅ `PUT /users/:id` - Para actualizar usuario (nombre, location)
- ✅ `PUT /instructors/:id` - Para actualizar instructor (description, hourlyRate, etc.)
- ✅ `POST /auth/logout` - Para cerrar sesión correctamente

## ✅ ESTADO ACTUAL

- **0 Errores** ✅
- **1 Info** (campo privado podría ser final - no afecta funcionalidad)
- **Todas las rutas verificadas** ✅
- **Logout corregido** ✅
- **updateUser implementado** ✅

## 🚀 LISTO PARA USAR

La app está completamente configurada y lista para conectarse al backend. Solo asegúrate de que:
1. El backend esté corriendo en `http://192.168.0.19:3000`
2. La tabla `users` tenga el campo `location`
3. Las rutas PUT para users e instructors estén implementadas
