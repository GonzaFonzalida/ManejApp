# Sistema de Autenticación

## Descripción
Sistema completo de autenticación con JWT tokens, roles de usuario y gestión de sesiones.

## Características Principales

### Login y Registro
- **Registro de usuarios** con validación de datos
- **Login con email/password** 
- **Detección automática de roles** (Instructor/Estudiante)
- **Redirección basada en rol** al dashboard correspondiente

### Gestión de Tokens
- **JWT tokens** para autenticación
- **Refresh tokens** para renovación automática
- **Almacenamiento seguro** con FlutterSecureStorage
- **Validación automática** de sesiones

### Roles de Usuario
- **Instructor**: Acceso a dashboard de instructor, gestión de horarios
- **Estudiante**: Acceso a dashboard de estudiante, reserva de clases

## Archivos Clave
- `lib/controllers/login_controller.dart` - Lógica de autenticación
- `lib/services/api_service.dart` - Comunicación con backend
- `lib/screens/login_screen.dart` - Interfaz de login

## Flujo de Autenticación
1. Usuario ingresa credenciales
2. Backend valida y retorna JWT token
3. Token se almacena de forma segura
4. Redirección automática según rol del usuario
5. Validación de token en cada request

## Logout
- Limpieza completa de datos de sesión
- Revocación de tokens en backend
- Redirección automática al login