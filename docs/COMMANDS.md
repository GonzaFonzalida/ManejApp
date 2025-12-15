# 🛠️ Comandos Útiles - ManejApp

## 📦 Instalación y Configuración

### Instalar dependencias
```bash
flutter pub get
```

### Limpiar proyecto
```bash
flutter clean
flutter pub get
```

### Verificar instalación
```bash
flutter doctor -v
```

## 🏃 Ejecutar la App

### Modo Debug
```bash
# Ejecutar en dispositivo conectado
flutter run

# Ejecutar en emulador específico
flutter run -d <device_id>

# Ver dispositivos disponibles
flutter devices

# Hot reload (durante ejecución)
# Presiona 'r' en la terminal

# Hot restart (durante ejecución)
# Presiona 'R' en la terminal
```

### Modo Release
```bash
# Ejecutar en modo release
flutter run --release

# Ejecutar en modo profile (para análisis de performance)
flutter run --profile
```

## 🔨 Build

### Android APK
```bash
# Build APK debug
flutter build apk --debug

# Build APK release
flutter build apk --release

# Build APK split por ABI (reduce tamaño)
flutter build apk --split-per-abi

# Build App Bundle (para Google Play)
flutter build appbundle --release
```

### Ubicación de builds
```
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

## 🧪 Testing

### Ejecutar tests
```bash
# Todos los tests
flutter test

# Test específico
flutter test test/widget_test.dart

# Con coverage
flutter test --coverage

# Ver coverage en HTML
genhtml coverage/lcov.info -o coverage/html
```

## 🔍 Análisis de Código

### Analizar código
```bash
# Análisis estático
flutter analyze

# Formatear código
flutter format .

# Formatear archivo específico
flutter format lib/main.dart
```

## 📱 Dispositivos y Emuladores

### Android
```bash
# Listar emuladores
flutter emulators

# Iniciar emulador
flutter emulators --launch <emulator_id>

# Listar dispositivos conectados
adb devices

# Instalar APK manualmente
adb install build/app/outputs/flutter-apk/app-release.apk

# Ver logs
adb logcat | grep flutter
```

## 🐛 Debug

### Logs y Debug
```bash
# Ver logs en tiempo real
flutter logs

# Limpiar logs
flutter logs --clear

# Inspeccionar app (DevTools)
flutter pub global activate devtools
flutter pub global run devtools

# Abrir DevTools
flutter run --observatory-port=9200
# Luego abrir: http://localhost:9200
```

## 📊 Performance

### Análisis de Performance
```bash
# Profile mode
flutter run --profile

# Trace performance
flutter run --profile --trace-startup

# Analizar tamaño del APK
flutter build apk --analyze-size
```

## 🔧 Mantenimiento

### Actualizar dependencias
```bash
# Ver dependencias desactualizadas
flutter pub outdated

# Actualizar dependencias
flutter pub upgrade

# Actualizar dependencia específica
flutter pub upgrade <package_name>
```

### Caché
```bash
# Limpiar caché de Flutter
flutter clean

# Limpiar caché de Gradle (Android)
cd android
./gradlew clean
cd ..

# Limpiar todo
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
```

## 🔐 Signing (Android)

### Generar keystore
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Verificar keystore
```bash
keytool -list -v -keystore ~/upload-keystore.jks -alias upload
```

## 📦 Dependencias

### Agregar dependencia
```bash
flutter pub add <package_name>

# Ejemplo
flutter pub add http
```

### Remover dependencia
```bash
flutter pub remove <package_name>
```

## 🌐 Firebase

### Configurar Firebase
```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase
flutterfire configure

# Actualizar configuración
flutterfire reconfigure
```

## 📱 Comandos Específicos de ManejApp

### Setup inicial completo
```bash
# 1. Limpiar e instalar
flutter clean
flutter pub get

# 2. Verificar configuración
flutter doctor -v

# 3. Ejecutar en debug
flutter run

# 4. Build release
flutter build apk --release --split-per-abi
```

### Desarrollo rápido
```bash
# Terminal 1: Ejecutar app
flutter run

# Terminal 2: Ver logs
flutter logs

# Durante desarrollo:
# - Presiona 'r' para hot reload
# - Presiona 'R' para hot restart
# - Presiona 'p' para mostrar grid de debug
# - Presiona 'o' para cambiar orientación
# - Presiona 'q' para salir
```

### Pre-release checklist
```bash
# 1. Analizar código
flutter analyze

# 2. Formatear código
flutter format .

# 3. Ejecutar tests
flutter test

# 4. Build release
flutter build apk --release

# 5. Verificar tamaño
flutter build apk --analyze-size

# 6. Test en dispositivo real
flutter install
```

## 🚀 Deploy

### Google Play Store
```bash
# 1. Build App Bundle
flutter build appbundle --release

# 2. Ubicación del archivo
# build/app/outputs/bundle/release/app-release.aab

# 3. Subir a Google Play Console
# https://play.google.com/console
```

### Distribución directa (APK)
```bash
# 1. Build APK
flutter build apk --release --split-per-abi

# 2. Ubicación de archivos
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk

# 3. Distribuir APK arm64-v8a (más común)
```

## 🔄 Git

### Comandos útiles
```bash
# Estado
git status

# Agregar cambios
git add .

# Commit
git commit -m "feat: descripción del cambio"

# Push
git push origin main

# Pull
git pull origin main

# Crear rama
git checkout -b feature/nueva-funcionalidad

# Ver ramas
git branch -a
```

## 📝 Notas Importantes

### Antes de cada build de producción:
1. ✅ Actualizar versión en `pubspec.yaml`
2. ✅ Ejecutar `flutter analyze`
3. ✅ Ejecutar `flutter test`
4. ✅ Probar en dispositivo real
5. ✅ Verificar que Firebase esté configurado
6. ✅ Verificar que las credenciales de MercadoPago sean de producción

### Solución de problemas comunes:
```bash
# Error de Gradle
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get

# Error de dependencias
flutter pub cache repair
flutter pub get

# Error de Firebase
flutterfire reconfigure

# Error de permisos (Linux/Mac)
chmod +x android/gradlew
```

## 🎯 Atajos de Teclado (VS Code)

- `Ctrl + Shift + P`: Command Palette
- `Ctrl + Space`: Autocompletado
- `F5`: Iniciar debug
- `Shift + F5`: Detener debug
- `Ctrl + F5`: Ejecutar sin debug
- `Ctrl + .`: Quick fix
- `Alt + Shift + F`: Formatear documento

## 📚 Recursos Útiles

- Flutter Docs: https://docs.flutter.dev
- Pub.dev: https://pub.dev
- Firebase Console: https://console.firebase.google.com
- MercadoPago Docs: https://www.mercadopago.com.ar/developers
- Google Play Console: https://play.google.com/console

---

**💡 Tip:** Guarda este archivo como referencia rápida durante el desarrollo.
