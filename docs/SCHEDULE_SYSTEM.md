# Sistema de Horarios y Reservas

## Descripción
Sistema completo para gestión de horarios de instructores y reservas de clases por estudiantes.

## Características Principales

### Gestión de Horarios (Instructores)
- **Creación de slots de tiempo** con fecha, hora inicio y fin
- **Validación de horarios** (no solapamiento, horarios futuros)
- **Eliminación de horarios** no reservados
- **Vista de calendario** con horarios disponibles y ocupados

### Sistema de Reservas (Estudiantes)
- **Búsqueda de instructores** con horarios disponibles
- **Reserva de slots** con creación automática de clase
- **Integración con pagos** vía Mercado Pago
- **Creación automática de registro de estudiante** si no existe

### Backend Integration
- **Upsert automático** de estudiantes en reservas
- **Validación de autenticación** en endpoints protegidos
- **Manejo de estados** de slots (disponible/reservado)

## Archivos Clave
- `lib/screens/instructor_schedule_screen.dart` - Gestión de horarios
- `lib/screens/reservar_clase_screen.dart` - Reserva de clases
- `lib/models/schedule_slot.dart` - Modelo de datos
- `lib/services/api_service.dart` - API endpoints

## Flujo de Reserva
1. Estudiante busca instructor
2. Ve horarios disponibles del instructor
3. Selecciona slot deseado
4. Sistema reserva slot y crea clase automáticamente
5. Genera preferencia de pago en Mercado Pago
6. Redirige a pantalla de pago

## Problemas Resueltos
- **Error 401**: Middleware de autenticación faltante
- **Error 404**: Creación automática de estudiante
- **Mapeo de IDs**: Diferencia entre userId y studentId
- **Serialización DateTime**: Manejo de campos vacíos del backend