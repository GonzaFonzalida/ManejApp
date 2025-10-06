# Sistema de Dashboards

## Descripción
Dashboards diferenciados para instructores y estudiantes con navegación por tabs y estadísticas.

## Dashboard de Instructor

### Características
- **Estadísticas de clases** (total, completadas, pendientes)
- **Próximas clases** con información del estudiante
- **Gestión de horarios** (crear, eliminar slots)
- **Navegación por tabs**: Dashboard, Horarios, Clases, Perfil

### Funcionalidades
- **Creación de horarios** con validación
- **Vista de clases programadas**
- **Edición de perfil profesional**
- **Logout con confirmación**

## Dashboard de Estudiante

### Características
- **Progreso de aprendizaje** (clases totales, completadas)
- **Próximas clases** programadas
- **Historial de pagos** recientes
- **Navegación por tabs**: Dashboard, Buscar, Mis Clases, Pagos, Perfil

### Funcionalidades
- **Búsqueda de instructores** con mapa
- **Reserva de clases** con pago integrado
- **Seguimiento de progreso**
- **Gestión de perfil personal**

## Archivos Clave
- `lib/screens/instructor_dashboard_screen.dart` - Dashboard instructor
- `lib/screens/student_dashboard_screen.dart` - Dashboard estudiante
- `lib/screens/home_screen.dart` - Búsqueda de instructores

## Navegación
- **Bottom Navigation Bar** con 4-5 tabs según rol
- **Redirección automática** basada en rol del usuario
- **Estado persistente** entre tabs

## Problemas Resueltos
- **Mapeo de studentId**: Corrección para mostrar clases del estudiante
- **Carga de datos**: Optimización de llamadas a API
- **Estados de carga**: Indicadores visuales apropiados