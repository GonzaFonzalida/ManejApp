# 🚀 Guía de Despliegue - ManejApp

## 📋 Pre-requisitos

Antes de desplegar, asegúrate de tener:
- ✅ Cuenta de Google Play Console
- ✅ Cuenta de Firebase (configurada)
- ✅ Cuenta de MercadoPago (modo producción)
- ✅ Keystore para firma de APK
- ✅ Backend en producción

---

## 🔐 Paso 1: Generar Keystore

### Crear Keystore
```bash
keytool -genkey -v -keystore ~/manejapp-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias manejapp
```

### Información requerida:
- **Contraseña del keystore:** (guárdala de forma segura)
- **Nombre y apellido:** Tu nombre
- **Unidad organizativa:** ManejApp
- **Organización:** Tu empresa
- **Ciudad:** Tu ciudad
- **Estado:** Tu provincia
- **Código de país:** AR

### Guardar información
Crea `android/key.properties`:
```properties
storePassword=TU_PASSWORD_KEYSTORE
keyPassword=TU_PASSWORD_KEY
keyAlias=manejapp
storeFile=C:/ruta/a/manejapp-keystore.jks
```

⚠️ **IMPORTANTE:** Nunca subas `key.properties` a Git!

---

## 🔥 Paso 2: Configurar Firebase

### 1. Crear Proyecto en Firebase
1. Ve a https://console.firebase.google.com/
2. Crea nuevo proyecto: "ManejApp Production"
3. Habilita Google Analytics (opcional)

### 2. Agregar App Android
1. Click en "Agregar app" → Android
2. Package name: `com.example.manejapp`
3. Nickname: "ManejApp Android"
4. Descargar `google-services.json`

### 3. Reemplazar Archivo
```bash
# Reemplazar el archivo demo con el real
cp ~/Downloads/google-services.json android/app/google-services.json
```

### 4. Habilitar Cloud Messaging
1. En Firebase Console → Cloud Messaging
2. Habilitar el servicio
3. Copiar Server Key para el backend

### 5. Configurar Backend
En tu backend, agrega la Server Key:
```env
FIREBASE_SERVER_KEY=tu_server_key_aqui
```

---

## 💳 Paso 3: Configurar MercadoPago

### 1. Obtener Credenciales de Producción
1. Ve a https://www.mercadopago.com.ar/developers
2. Ve a "Tus integraciones"
3. Copia las credenciales de **Producción**:
   - Access Token
   - Public Key

### 2. Configurar Backend
```env
MERCADOPAGO_ACCESS_TOKEN=tu_access_token_produccion
MERCADOPAGO_PUBLIC_KEY=tu_public_key_produccion
MERCADOPAGO_WEBHOOK_URL=https://tu-backend.com/api/v1/payments/mercadopago/webhook
```

### 3. Configurar Webhook
1. En MercadoPago Developers → Webhooks
2. Agregar nueva URL: `https://tu-backend.com/api/v1/payments/mercadopago/webhook`
3. Seleccionar eventos:
   - payment
   - merchant_order

---

## 🏗️ Paso 4: Preparar el Código

### 1. Actualizar Versión
En `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Incrementar para cada release
```

### 2. Actualizar URL del Backend
En `lib/services/api_service.dart`:
```dart
static const String _baseUrl = 'https://tu-backend-produccion.com/api/v1';
```

### 3. Verificar Configuración
```bash
# Analizar código
flutter analyze

# Formatear código
flutter format .

# Ejecutar tests
flutter test
```

---

## 📦 Paso 5: Build de Producción

### Opción A: APK (Distribución Directa)
```bash
# Build APK firmado
flutter build apk --release --split-per-abi

# Ubicación de archivos:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### Opción B: App Bundle (Google Play)
```bash
# Build App Bundle firmado
flutter build appbundle --release

# Ubicación del archivo:
# build/app/outputs/bundle/release/app-release.aab
```

### Verificar Firma
```bash
# Verificar que el APK esté firmado
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
```

---

## 🎮 Paso 6: Google Play Console

### 1. Crear App
1. Ve a https://play.google.com/console
2. Click en "Crear app"
3. Completa la información:
   - Nombre: ManejApp
   - Idioma predeterminado: Español
   - Tipo: App
   - Categoría: Educación

### 2. Configurar Ficha de Play Store

#### Descripción Corta (80 caracteres)
```
Aprende a manejar con instructores profesionales. Reserva, paga y aprende.
```

#### Descripción Completa (4000 caracteres)
```
🚗 ManejApp - Tu Escuela de Manejo Digital

ManejApp es la aplicación definitiva para aprender a manejar. Conectamos estudiantes con instructores profesionales de manera fácil, rápida y segura.

✨ CARACTERÍSTICAS PRINCIPALES

📱 Para Estudiantes:
• Busca instructores disponibles cerca de ti
• Reserva clases en segundos
• Paga de forma segura con MercadoPago
• Sigue tu progreso con estadísticas detalladas
• Califica tu experiencia
• Chat directo con tu instructor

👨‍🏫 Para Instructores:
• Gestiona tu agenda fácilmente
• Recibe reservas automáticamente
• Completa clases con notas para tus alumnos
• Configura tus tarifas
• Chat con tus estudiantes
• Panel de control con métricas

💳 PAGOS SEGUROS
Integración completa con MercadoPago para pagos 100% seguros y confiables.

🔔 NOTIFICACIONES
Recibe notificaciones de nuevas reservas, recordatorios de clases y más.

🎯 ¿POR QUÉ MANEJAPP?
• Fácil de usar
• Seguro y confiable
• Instructores verificados
• Soporte 24/7
• Sin comisiones ocultas

📞 SOPORTE
¿Necesitas ayuda? Contáctanos en soporte@manejapp.app

Descarga ManejApp ahora y comienza tu camino hacia la licencia de conducir. 🚗💨
```

### 3. Recursos Gráficos

#### Icono de la App (512x512 px)
- Formato: PNG
- Sin transparencia
- Fondo sólido

#### Gráfico de Funciones (1024x500 px)
- Banner promocional
- Muestra características principales

#### Capturas de Pantalla (mínimo 2)
- Tamaño: 1080x1920 px o 1080x2340 px
- Formato: PNG o JPG
- Capturas de:
  - Pantalla de inicio
  - Dashboard
  - Reserva de clase
  - Perfil

### 4. Clasificación de Contenido
1. Completa el cuestionario
2. Categoría: Educación
3. Sin contenido sensible

### 5. Política de Privacidad
Crea una página web con tu política de privacidad:
```
https://tu-sitio.com/privacy-policy
```

### 6. Subir App Bundle
1. Ve a "Producción" → "Crear nueva versión"
2. Sube `app-release.aab`
3. Completa notas de la versión:
```
Versión 1.0.0
• Lanzamiento inicial
• Sistema completo de reservas
• Pagos con MercadoPago
• Chat con instructores
• Panel administrativo
```

### 7. Revisar y Publicar
1. Revisa toda la información
2. Click en "Enviar para revisión"
3. Espera aprobación (1-7 días)

---

## 🧪 Paso 7: Testing Pre-Producción

### Testing Interno
1. En Play Console → Testing → Testing interno
2. Crea lista de testers
3. Sube versión de prueba
4. Comparte link con testers

### Testing Cerrado
1. Crea grupo de beta testers (20-100 personas)
2. Sube versión beta
3. Recopila feedback
4. Corrige bugs

### Checklist de Testing
- [ ] Login y registro funcionan
- [ ] Reserva de clases funciona
- [ ] Pagos se procesan correctamente
- [ ] Notificaciones llegan
- [ ] Chat funciona
- [ ] Todas las pantallas cargan
- [ ] No hay crashes
- [ ] Performance es buena

---

## 📊 Paso 8: Monitoreo Post-Lanzamiento

### Firebase Analytics
```dart
// Ya configurado en la app
// Ver métricas en Firebase Console
```

### Crashlytics
```bash
# Agregar a pubspec.yaml
firebase_crashlytics: ^3.4.0

# Configurar en main.dart
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
```

### Play Console Métricas
- Instalaciones
- Desinstalaciones
- Calificaciones
- Reseñas
- Crashes (ANR)

---

## 🔄 Paso 9: Actualizaciones

### Para cada actualización:

1. **Incrementar versión** en `pubspec.yaml`:
```yaml
version: 1.0.1+2  # 1.0.1 = version name, 2 = version code
```

2. **Build nueva versión**:
```bash
flutter build appbundle --release
```

3. **Subir a Play Console**:
- Producción → Crear nueva versión
- Subir nuevo AAB
- Agregar notas de la versión

4. **Publicar**:
- Revisar cambios
- Enviar para revisión

---

## 🚨 Troubleshooting

### Error: "App not signed"
```bash
# Verificar key.properties
cat android/key.properties

# Verificar que el keystore existe
ls -la ~/manejapp-keystore.jks
```

### Error: "Firebase not configured"
```bash
# Verificar google-services.json
cat android/app/google-services.json

# Reconfigurar Firebase
flutterfire reconfigure
```

### Error: "MercadoPago payment fails"
```bash
# Verificar credenciales en backend
# Verificar webhook configurado
# Ver logs del backend
```

### App rechazada por Google
- Revisa el email de Google Play
- Corrige los problemas indicados
- Vuelve a subir

---

## 📝 Checklist Final

Antes de publicar, verifica:

### Código
- [ ] Versión actualizada en pubspec.yaml
- [ ] URL del backend apunta a producción
- [ ] Firebase configurado con proyecto real
- [ ] MercadoPago en modo producción
- [ ] Todos los tests pasan
- [ ] No hay warnings en flutter analyze

### Play Console
- [ ] Descripción completa
- [ ] Capturas de pantalla subidas
- [ ] Icono de app configurado
- [ ] Política de privacidad publicada
- [ ] Clasificación de contenido completada
- [ ] App Bundle subido y firmado

### Backend
- [ ] Servidor en producción funcionando
- [ ] Base de datos configurada
- [ ] Webhooks de MercadoPago configurados
- [ ] Firebase Server Key configurada
- [ ] SSL/HTTPS habilitado

### Testing
- [ ] Testeado en dispositivos reales
- [ ] Testeado en diferentes versiones de Android
- [ ] Todos los flujos funcionan
- [ ] Pagos funcionan correctamente
- [ ] Notificaciones llegan

---

## 🎉 ¡Listo para Producción!

Una vez completados todos los pasos:
1. ✅ App publicada en Google Play
2. ✅ Backend en producción
3. ✅ Firebase configurado
4. ✅ MercadoPago funcionando
5. ✅ Monitoreo activo

**¡ManejApp está en vivo! 🚀**

---

## 📞 Soporte Post-Lanzamiento

### Monitoreo Diario
- Revisar crashes en Play Console
- Revisar métricas en Firebase
- Responder reseñas de usuarios
- Monitorear pagos en MercadoPago

### Actualizaciones Regulares
- Corrección de bugs: cada 1-2 semanas
- Nuevas funcionalidades: cada 1-2 meses
- Actualizaciones de seguridad: inmediatas

---

**¡Éxito con el lanzamiento! 🎊**
