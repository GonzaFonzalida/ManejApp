# ManejApp - Aplicación de Autoescuela

ManejApp es una aplicación móvil desarrollada en Flutter para gestionar clases de manejo, conectando estudiantes con instructores profesionales.

## 🚀 Características

### Para Estudiantes
- 📅 Reserva de clases con instructores disponibles
- 💳 Pagos seguros integrados con MercadoPago
- 💬 Chat en tiempo real con instructores
- 📊 Seguimiento de progreso y clases completadas
- ⭐ Sistema de calificaciones y feedback
- 📍 Visualización de ubicación de instructores en mapa
- 🔔 Notificaciones push y locales

### Para Instructores
- 📋 Gestión de clases programadas
- 🚗 Registro de vehículos
- 💰 Visualización de ingresos
- 📝 Notas y feedback para estudiantes
- 📊 Dashboard con estadísticas

### Para Administradores
- 👥 Gestión de usuarios (estudiantes e instructores)
- 📈 Estadísticas generales del sistema
- 🔧 Configuración de la plataforma

## 📱 Capturas de Pantalla

[Agregar capturas aquí]

## 🛠️ Tecnologías Utilizadas

- **Framework**: Flutter 3.8+
- **Lenguaje**: Dart
- **Estado**: Provider
- **Almacenamiento**: SharedPreferences, FlutterSecureStorage
- **Mapas**: Google Maps / Flutter Map
- **Notificaciones**: Firebase Cloud Messaging
- **Pagos**: MercadoPago API
- **Backend**: API REST (Node.js/Express)

## 📦 Dependencias Principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
  http: ^1.1.0
  shared_preferences: ^2.5.3
  flutter_secure_storage: ^9.0.0
  google_maps_flutter: ^2.9.0
  firebase_core: ^3.8.1
  firebase_messaging: ^15.1.5
  flutter_local_notifications: ^18.0.1
  table_calendar: ^3.1.2
  shimmer: ^3.0.0
  cached_network_image: ^3.4.1
```

## 🚀 Instalación

### Prerrequisitos
- Flutter SDK (3.8 o superior)
- Android Studio / Xcode
- Cuenta de Firebase (para notificaciones)
- Cuenta de MercadoPago (para pagos)

### Pasos

1. Clona el repositorio:
```bash
git clone https://github.com/tu-usuario/manejapp.git
cd manejapp
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Configura Firebase:
   - Descarga `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
   - Colócalos en las carpetas correspondientes

4. Configura el archivo de configuración:
```bash
cp lib/services/config_example.json lib/services/config.json
```

Edita `config.json` con tus credenciales:
```json
{
  "apiBaseUrl": "https://tu-api.com/api/v1",
  "mercadoPagoPublicKey": "TU_PUBLIC_KEY"
}
```

5. Ejecuta la aplicación:
```bash
flutter run
```

## 🏗️ Estructura del Proyecto

```
lib/
├── controllers/        # Lógica de negocio y estado
├── models/            # Modelos de datos
├── providers/         # Providers (tema, etc.)
├── screens/           # Pantallas de la app
├── services/          # Servicios (API, notificaciones)
├── utils/             # Utilidades (validadores, caché)
├── widgets/           # Widgets reutilizables
└── main.dart          # Punto de entrada
```

## 🔧 Configuración del Backend

La app requiere un backend REST con los siguientes endpoints:

### Autenticación
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/logout`

### Usuarios
- `GET /api/v1/users/:id`
- `PUT /api/v1/users/:id`

### Clases
- `GET /api/v1/driving-classes`
- `POST /api/v1/driving-classes`
- `PUT /api/v1/driving-classes/:id`
- `DELETE /api/v1/driving-classes/:id`

### Mensajería
- `POST /api/v1/messages/send`
- `GET /api/v1/messages/conversations`
- `GET /api/v1/messages/conversations/:id/messages`

### Pagos
- `POST /api/v1/payments`
- `GET /api/v1/payments`

Ver documentación completa del backend en `/docs/API.md`

## 🎨 Temas y Personalización

La app soporta modo claro y oscuro. Para cambiar el tema:
1. Ve a Configuración
2. Activa "Modo Oscuro"

Los colores principales se definen en `lib/utils/constants.dart`:
```dart
static const primaryColor = Color(0xFF003087);
```

## 🧪 Testing

Ejecutar tests:
```bash
flutter test
```

## 📱 Generación de APK/IPA

### Android (APK)
```bash
flutter build apk --release
```

### Android (App Bundle)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔐 Seguridad

- Las credenciales se almacenan en FlutterSecureStorage
- Tokens JWT para autenticación
- Comunicación HTTPS con el backend
- Validación de inputs en formularios

## 🐛 Problemas Conocidos

1. **Imagen de perfil**: El endpoint de subida de imagen puede no estar implementado en el backend
2. **Notificaciones push**: Requiere configuración completa de FCM en el backend
3. **Student no encontrado**: Si un usuario con rol student no tiene registro en la tabla Student, las reservas pueden fallar

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 👥 Contribuidores

- [Tu Nombre] - Desarrollo inicial

## 📞 Soporte

Para reportar bugs o solicitar features, abre un issue en GitHub.

## 🔄 Changelog

### v1.0.0 (2024)
- ✅ Sistema de autenticación completo
- ✅ Reserva de clases
- ✅ Integración con MercadoPago
- ✅ Chat en tiempo real
- ✅ Notificaciones locales
- ✅ Modo oscuro
- ✅ Calendario de clases
- ✅ Sistema de búsqueda y filtros
- ✅ Skeleton loaders
- ✅ Caché offline

## 🚀 Roadmap

- [ ] Videollamadas con instructores
- [ ] Sistema de exámenes teóricos
- [ ] Gamificación y logros
- [ ] Integración con redes sociales
- [ ] Soporte multiidioma
