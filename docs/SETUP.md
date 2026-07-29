# ManejApp - Guía de Configuración Completa

## 🚀 Características Implementadas

### ✅ Completamente Funcional
- **Autenticación**: Login, registro, JWT, refresh tokens
- **Estudiantes**: Dashboard, clases, pagos, reservas, calificaciones
- **Instructores**: Dashboard, gestión de clases, horarios, perfil
- **Administradores**: Dashboard con estadísticas, gestión de usuarios, reportes
- **Pagos**: Integración completa con MercadoPago
- **Chat**: Sistema de mensajería entre instructor y estudiante
- **Notificaciones**: Push notifications con Firebase
- **Configuración**: Pantalla de ajustes completa
- **Imágenes**: Subida de fotos de perfil y documentos

## 📋 Requisitos Previos

- Flutter SDK 3.8.1 o superior
- Android Studio / VS Code
- Cuenta de Firebase (para notificaciones push)
- Cuenta de MercadoPago (para pagos)

## 🔧 Instalación

### 1. Instalar Dependencias

```bash
flutter pub get
```

### 2. Configurar Firebase

#### Paso 1: Crear proyecto en Firebase Console
1. Ve a https://console.firebase.google.com/
2. Crea un nuevo proyecto llamado "ManejApp"
3. Agrega una app Android con el package name: `com.example.manejapp`

#### Paso 2: Descargar google-services.json
1. Descarga el archivo `google-services.json` de Firebase Console
2. Reemplaza el archivo en: `android/app/google-services.json`

#### Paso 3: Habilitar Cloud Messaging
1. En Firebase Console, ve a "Cloud Messaging"
2. Habilita el servicio
3. Copia la Server Key para el backend

### 3. Configurar Backend

Asegúrate de que el backend esté corriendo en:
```
http://72.60.166.178:3000/api/v1
```

O actualiza la URL en `lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'TU_URL_BACKEND/api/v1';
```

### 4. Configurar MercadoPago

En el backend, configura las credenciales de MercadoPago en las variables de entorno:
```
MERCADOPAGO_ACCESS_TOKEN=tu_access_token
MERCADOPAGO_PUBLIC_KEY=tu_public_key
```

### 5. Google Maps SDK (Android e iOS)

La app usa `google_maps_flutter`. **No pongas la API key en código Dart**; configurá por plataforma:

**Android**

1. En [Google Cloud Console](https://console.cloud.google.com/) creá una API key con **Maps SDK for Android** habilitado (restringila por firma del app / package `com.manejapp_.app`).
2. Agregá la línea en `ManejApp-frontend/android/local.properties` (archivo listado en `.gitignore` del proyecto; no commitear la clave):
   ```properties
   GOOGLE_MAPS_API_KEY=tu_clave_aqui
   ```
   Alternativa: variable de entorno `GOOGLE_MAPS_API_KEY` al compilar.
3. El `AndroidManifest` usa el placeholder `${GOOGLE_MAPS_API_KEY}` inyectado por `android/app/build.gradle.kts`.

**iOS**

1. Creá otra API key (o la misma política permitiendo iOS) con **Maps SDK for iOS** habilitado; restringila por **bundle ID** (`com.gonzalofonzalida.manejapp` según el proyecto).
2. Copiá `ios/Flutter/Secrets.xcconfig.example` a `ios/Flutter/Secrets.xcconfig` y asigná `GOOGLE_MAPS_API_KEY` (este archivo está en `.gitignore`).
3. `Info.plist` usa `GMSApiKey` = `$(GOOGLE_MAPS_API_KEY)` sustituido por Xcode desde los `.xcconfig`.
4. `AppDelegate.swift` llama a `GMSServices.provideAPIKey` leyendo esa clave del bundle tras el merge del Info.plist.

## 🏃 Ejecutar la Aplicación

### Modo Debug
```bash
flutter run
```

### Modo Release
```bash
flutter build apk --release
```

El APK se generará en: `build/app/outputs/flutter-apk/app-release.apk`

## 📱 Funcionalidades por Rol

### Estudiante
- ✅ Dashboard con estadísticas personales
- ✅ Buscar y reservar clases con instructores
- ✅ Ver historial de clases (programadas, completadas, canceladas)
- ✅ Calificar clases completadas
- ✅ Gestionar pagos
- ✅ Chat con instructores
- ✅ Perfil y configuración

### Instructor
- ✅ Dashboard con resumen del día
- ✅ Gestión de horarios disponibles
- ✅ Ver clases asignadas
- ✅ Completar clases con notas
- ✅ Chat con estudiantes
- ✅ Editar perfil profesional
- ✅ Configurar tarifa por hora

### Administrador
- ✅ Dashboard con métricas generales
- ✅ Gestión de usuarios (estudiantes e instructores)
- ✅ Reportes y estadísticas con gráficos
- ✅ Configuración del sistema
- ✅ Exportación de datos

## 🔔 Notificaciones Push

Las notificaciones se envían automáticamente para:
- Nueva clase reservada
- Clase próxima (1 hora antes)
- Clase completada
- Pago confirmado
- Mensajes de chat

## 💳 Flujo de Pagos

1. Estudiante reserva una clase
2. Se crea una preferencia de pago en MercadoPago
3. Estudiante completa el pago
4. Webhook actualiza el estado
5. Notificación de confirmación

## 🎨 Personalización

### Colores
El color principal de la app es `#003087` (azul oscuro).
Para cambiarlo, edita en `lib/main.dart`:
```dart
colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003087)),
```

### Logo
Reemplaza los archivos en:
- `android/app/src/main/res/mipmap-*/ic_launcher.png`
- `assets/` (para imágenes internas)

## 🐛 Solución de Problemas

### Error de Firebase
Si ves errores de Firebase:
1. Verifica que `google-services.json` esté en la ubicación correcta
2. Ejecuta `flutter clean && flutter pub get`
3. Reconstruye la app

### Error de Conexión al Backend
1. Verifica que el backend esté corriendo
2. Verifica la URL en `api_service.dart`
3. Verifica permisos de red en `AndroidManifest.xml`

### Error de MercadoPago
1. Verifica las credenciales en el backend
2. Verifica que el webhook esté configurado correctamente
3. Revisa los logs del backend

## 📚 Estructura del Proyecto

```
lib/
├── controllers/          # Lógica de negocio
├── models/              # Modelos de datos
├── screens/             # Pantallas de la app
│   ├── admin_*.dart    # Pantallas de admin
│   ├── instructor_*.dart # Pantallas de instructor
│   ├── student_*.dart  # Pantallas de estudiante
│   └── *.dart          # Pantallas generales
├── services/            # Servicios (API, notificaciones, imágenes)
└── main.dart           # Punto de entrada
```

## 🚀 Próximas Mejoras

- [ ] Modo oscuro
- [ ] Soporte multiidioma
- [ ] Integración con Google Maps para rutas
- [ ] Sistema de reputación público
- [ ] Exportación de certificados
- [ ] Integración con calendario del dispositivo

## 📞 Soporte

Para problemas o preguntas:
- Email: soporte@manejapp.app
- GitHub Issues: [tu-repo]/issues

## 📄 Licencia

© 2024 ManejApp. Todos los derechos reservados.
