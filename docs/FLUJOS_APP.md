# Flujos de la Aplicación ManejApp

## 📱 Flujo de Onboarding y Autenticación

### Primera Vez (Onboarding)
1. Usuario abre la app por primera vez
2. Se muestra onboarding mejorado con 5 pantallas:
   - Bienvenida
   - Reserva de clases
   - Pagos seguros
   - Chat con instructores
   - Seguimiento de progreso
3. Usuario completa onboarding
4. Se guarda flag `first_launch_completed`
5. Redirige a pantalla de login

### Login
1. Usuario ingresa email y contraseña
2. Sistema valida credenciales con backend
3. Backend retorna JWT token y datos de usuario
4. Token se guarda en FlutterSecureStorage
5. Según rol, redirige a:
   - **ADMIN** → AdminDashboardScreen
   - **INSTRUCTOR** → InstructorDashboardScreen
   - **STUDENT** → StudentDashboardScreen

### Registro
1. Usuario selecciona "Registrarse"
2. Completa formulario con validaciones:
   - Email válido
   - Contraseña (mín 6 caracteres, 1 mayúscula, 1 número)
   - Nombre y apellido
   - Teléfono
3. Sistema crea usuario en backend
4. Redirige a selección de rol
5. Usuario elige STUDENT o INSTRUCTOR
6. Sistema actualiza rol
7. Redirige a dashboard correspondiente

---

## 👨‍🎓 Flujo del Estudiante

### Reservar Clase
1. Estudiante va a "Reservar Clase"
2. Sistema carga lista de instructores disponibles
3. Estudiante selecciona instructor
4. Elige fecha y hora disponible
5. Confirma reserva
6. Sistema crea clase con estado SCHEDULED
7. Redirige a pantalla de pago

### Realizar Pago
1. Sistema genera preferencia de MercadoPago
2. Abre WebView con checkout de MercadoPago
3. Usuario completa pago
4. MercadoPago redirige con resultado
5. Sistema actualiza estado del pago
6. Muestra confirmación al usuario

### Ver Clases
1. Estudiante va a "Mis Clases"
2. Sistema carga clases del estudiante
3. Muestra tabs:
   - **Todas**: Todas las clases
   - **Programadas**: Estado SCHEDULED
   - **Completadas**: Estado COMPLETED
   - **Canceladas**: Estado CANCELLED
4. Puede buscar por nombre de instructor
5. Puede cancelar clases programadas (con confirmación)
6. Puede calificar clases completadas

### Chat con Instructor
1. Estudiante selecciona instructor
2. Sistema verifica si tiene pago confirmado
3. Si no tiene pago → muestra mensaje de restricción
4. Si tiene pago → abre chat
5. Puede enviar mensajes en tiempo real
6. Mensajes se marcan como leídos automáticamente

### Ver Pagos
1. Estudiante va a "Mis Pagos"
2. Sistema carga historial de pagos
3. Muestra lista con:
   - Monto
   - Estado (pending, paid, failed)
   - Fecha
   - Descripción
4. Muestra total pagado al final

---

## 👨‍🏫 Flujo del Instructor

### Ver Clases Programadas
1. Instructor abre dashboard
2. Sistema carga clases asignadas
3. Muestra próximas clases con:
   - Estudiante
   - Fecha y hora
   - Estado
4. Puede ver detalles de cada clase

### Gestionar Vehículo
1. Instructor va a "Mi Vehículo"
2. Si no tiene vehículo → formulario de registro
3. Si tiene vehículo → muestra detalles
4. Puede editar información:
   - Marca y modelo
   - Año
   - Patente
   - Foto

### Completar Clase
1. Instructor marca clase como completada
2. Puede agregar notas para el estudiante
3. Sistema actualiza estado a COMPLETED
4. Estudiante recibe notificación

### Ver Ingresos
1. Instructor va a "Ingresos"
2. Sistema calcula total de pagos recibidos
3. Muestra gráfico de ingresos por mes
4. Lista de pagos detallada

---

## 👨‍💼 Flujo del Administrador

### Gestionar Usuarios
1. Admin abre dashboard
2. Ve estadísticas generales:
   - Total usuarios
   - Total estudiantes
   - Total instructores
   - Total clases
3. Puede ver lista de usuarios
4. Puede editar o eliminar usuarios

### Ver Estadísticas
1. Admin ve gráficos de:
   - Clases por mes
   - Ingresos totales
   - Usuarios activos
   - Tasa de cancelación

---

## 💬 Flujo de Mensajería

### Iniciar Conversación
1. Usuario A quiere contactar a Usuario B
2. Sistema verifica restricciones (pago para estudiantes)
3. Usuario A envía primer mensaje
4. Backend crea conversación automáticamente
5. Usuario B recibe notificación

### Chat en Tiempo Real
1. Usuario abre conversación
2. Sistema carga mensajes históricos
3. Marca mensajes como leídos
4. Polling cada 5 segundos para nuevos mensajes
5. Muestra indicador de no leídos en badge

### Búsqueda de Conversaciones
1. Usuario va a "Mensajes"
2. Ve lista de conversaciones
3. Puede buscar por nombre de contacto
4. Filtra en tiempo real

---

## 🔔 Flujo de Notificaciones

### Notificaciones Locales
1. Evento ocurre (nueva clase, pago confirmado)
2. Sistema crea notificación local
3. Usuario ve notificación en bandeja
4. Al tocar, abre pantalla correspondiente

### Notificaciones Push (Requiere backend)
1. Backend detecta evento
2. Envía push a FCM con token del usuario
3. FCM entrega notificación al dispositivo
4. Usuario ve notificación
5. Al tocar, abre app en pantalla específica

---

## 🎨 Flujo de Personalización

### Cambiar Tema
1. Usuario va a Configuración
2. Activa "Modo Oscuro"
3. Sistema guarda preferencia en SharedPreferences
4. App se actualiza inmediatamente
5. Tema persiste entre sesiones

### Editar Perfil
1. Usuario va a "Editar Perfil"
2. Puede cambiar:
   - Foto de perfil
   - Nombre y apellido
   - Teléfono
   - Ubicación
3. Sistema valida datos
4. Guarda cambios en backend
5. Actualiza UI

---

## 🔒 Flujo de Seguridad

### Validación de Sesión
1. App inicia
2. Sistema verifica token JWT en storage
3. Si no existe → redirige a login
4. Si existe → valida con backend
5. Si válido → redirige a dashboard
6. Si inválido → limpia storage y redirige a login

### Cierre de Sesión
1. Usuario selecciona "Cerrar Sesión"
2. Sistema muestra confirmación
3. Usuario confirma
4. Sistema:
   - Elimina token JWT
   - Limpia caché
   - Limpia datos sensibles
5. Redirige a login

---

## 📊 Flujo de Caché y Offline

### Caché de Datos
1. App hace request a API
2. Sistema guarda respuesta en caché con timestamp
3. Próximo request verifica caché primero
4. Si caché válido (< 15 min) → usa caché
5. Si caché expirado → hace request nuevo

### Modo Offline
1. Usuario pierde conexión
2. App detecta error de red
3. Intenta cargar desde caché
4. Si hay caché → muestra datos
5. Si no hay caché → muestra mensaje de error
6. Cuando recupera conexión → sincroniza datos

---

## 🔄 Flujo de Actualización de Datos

### Pull to Refresh
1. Usuario desliza hacia abajo en lista
2. Sistema muestra indicador de carga
3. Hace request a API
4. Actualiza caché
5. Refresca UI con nuevos datos

### Auto-refresh
1. Usuario abre pantalla de chat
2. Sistema inicia polling cada 5 segundos
3. Verifica nuevos mensajes
4. Si hay nuevos → actualiza UI
5. Al salir de pantalla → detiene polling

---

## 📅 Flujo de Calendario

### Ver Calendario
1. Usuario va a "Calendario"
2. Sistema carga clases del mes actual
3. Muestra calendario con marcadores en días con clases
4. Usuario selecciona día
5. Muestra lista de clases de ese día con:
   - Hora
   - Estado
   - Instructor/Estudiante

### Filtrar por Estado
1. Usuario selecciona filtro (Todas, Programadas, etc.)
2. Sistema filtra clases
3. Actualiza marcadores en calendario
4. Actualiza lista de clases

---

## 🔍 Flujo de Búsqueda

### Búsqueda en Listas
1. Usuario ingresa texto en barra de búsqueda
2. Sistema filtra en tiempo real
3. Muestra resultados coincidentes
4. Si no hay resultados → muestra mensaje
5. Al borrar búsqueda → muestra todos los items

### Búsqueda Avanzada (Futuro)
1. Usuario abre filtros avanzados
2. Selecciona múltiples criterios
3. Sistema aplica filtros combinados
4. Muestra resultados
5. Puede guardar búsqueda como favorita
