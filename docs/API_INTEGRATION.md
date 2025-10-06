# Integración con API Backend

## Descripción
Sistema completo de comunicación con backend REST API con manejo de autenticación y errores.

## Características Principales

### Autenticación
- **JWT Bearer tokens** en headers
- **Refresh automático** de tokens expirados
- **Manejo de errores 401** con reautenticación
- **Almacenamiento seguro** de credenciales

### Endpoints Principales

#### Usuarios y Autenticación
- `POST /users/register` - Registro de usuarios
- `POST /users/login` - Inicio de sesión
- `GET /users/:id` - Obtener perfil de usuario
- `PATCH /users/:id/role` - Actualizar rol de usuario

#### Instructores
- `GET /instructors` - Listar instructores
- `POST /instructors/register` - Registro como instructor
- `PUT /instructors/:id` - Actualizar perfil de instructor

#### Horarios y Clases
- `POST /schedule/slots` - Crear slot de horario
- `GET /schedule/instructor/:id` - Horarios de instructor
- `POST /schedule/reserve/:slotId` - Reservar slot
- `DELETE /schedule/:slotId` - Eliminar slot

#### Pagos
- `POST /payments/mercadopago/preference` - Crear preferencia de pago
- `GET /payments/mercadopago/status/:id` - Estado de pago

## Archivos Clave
- `lib/services/api_service.dart` - Cliente API principal
- Configuración de base URL y headers

## Manejo de Errores
- **Códigos HTTP** apropiados
- **Mensajes de error** descriptivos
- **Retry automático** en fallos de red
- **Fallbacks** para datos faltantes

## Configuración
- **Base URL**: `http://192.168.0.18:3000`
- **Headers**: Content-Type, Authorization
- **Timeouts**: Configurados para requests largos

## Problemas Resueltos
- **Serialización DateTime**: Campos vacíos del backend
- **Mapeo de IDs**: Diferencias entre userId/studentId/instructorId
- **Autenticación**: Middleware faltante en rutas protegidas