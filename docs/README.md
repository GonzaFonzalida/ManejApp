# ManejApp - Documentación

## Descripción General
ManejApp es una aplicación móvil para conectar estudiantes de manejo con instructores, permitiendo la reserva de clases y gestión de horarios con pagos integrados.

## Arquitectura de la Aplicación

### Frontend (Flutter)
- **Lenguaje**: Dart
- **Framework**: Flutter
- **Estado**: StatefulWidget con setState
- **Almacenamiento**: FlutterSecureStorage para datos sensibles
- **HTTP**: package:http para comunicación con API

### Backend Integration
- **API REST** con autenticación JWT
- **Base de datos**: PostgreSQL
- **Pagos**: Mercado Pago API
- **Autenticación**: JWT tokens con refresh

## Funcionalidades Principales

### Para Instructores
- ✅ Dashboard con estadísticas
- ✅ Gestión de horarios disponibles
- ✅ Vista de clases programadas
- ✅ Edición de perfil profesional
- ✅ Sistema de logout seguro

### Para Estudiantes
- ✅ Búsqueda de instructores con mapa
- ✅ Reserva de clases con pago
- ✅ Dashboard con progreso
- ✅ Historial de clases y pagos
- ✅ Gestión de perfil personal

## Documentación Detallada

- [**Sistema de Autenticación**](./AUTHENTICATION.md) - Login, registro y gestión de sesiones
- [**Sistema de Horarios**](./SCHEDULE_SYSTEM.md) - Gestión de horarios y reservas
- [**Integración de Pagos**](./PAYMENT_INTEGRATION.md) - Mercado Pago y procesamiento
- [**Sistema de Dashboards**](./DASHBOARD_SYSTEM.md) - Interfaces de usuario por rol
- [**Integración con API**](./API_INTEGRATION.md) - Comunicación con backend

## Instalación y Configuración

### Requisitos
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / VS Code
- Dispositivo Android o emulador

### Configuración
1. Clonar repositorio
2. Ejecutar `flutter pub get`
3. Configurar URL del backend en `api_service.dart`
4. Ejecutar `flutter run`

## Estado Actual
- ✅ Autenticación completa
- ✅ Dashboards funcionales
- ✅ Sistema de reservas operativo
- ✅ Integración de pagos activa
- ✅ Gestión de horarios implementada

## Próximas Funcionalidades
- 🔄 Notificaciones push
- 🔄 Chat entre instructor y estudiante
- 🔄 Sistema de calificaciones
- 🔄 Reportes y analytics