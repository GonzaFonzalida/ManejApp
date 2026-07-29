# Demo en iPhone físico — checklist y Xcode

Referencias del proyecto: `ios/Runner/Info.plist`, `ios/Flutter/Secrets.xcconfig` (local, no commiteado), `ios/Flutter/Secrets.xcconfig.example`.

## Qué ya está en el repo (no requiere código nuevo)

- **Bundle ID:** `com.gonzalofonzalida.manejapp`
- **Signing automático** y `DEVELOPMENT_TEAM` en Xcode (debes coincidir con tu cuenta o cambiarlo en Xcode)
- **Google Maps:** `GMSApiKey` vía `Secrets.xcconfig`
- **Google Sign-In:** `GIDClientID`, URL schemes (cliente iOS invertido + `manejapp`) vía `Secrets.xcconfig`
- **Face ID:** `NSFaceIDUsageDescription`
- **Ubicación:** `NSLocationWhenInUseUsageDescription`
- **Galería / cámara:** `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription` (necesarios para `ImagePicker` en dispositivo)
- **ATS:** permite HTTP/red local para desarrollo (`NSAllowsArbitraryLoads` / local networking)

## Qué tenés que hacer vos en Xcode (manual)

1. Abrí `ios/Runner.xcworkspace` (no el `.xcodeproj` suelto).
2. **Signing & Capabilities** → target **Runner**:
   - Marcá **Automatically manage signing**.
   - Elegí **Team** con tu Apple ID (si no coincide con el team del proyecto, Xcode lo cambiará o te pedirá ajustar el Bundle ID en un equipo personal).
3. Conectá el iPhone por cable, **Trust** en el teléfono si pide.
4. Seleccioná tu dispositivo como destino y pulsá **Run** (o desde terminal: `flutter run --release` con el device seleccionado).

### Push (FCM) en dispositivo real

- En el repo **no** hay `GoogleService-Info.plist`: conviene añadirlo desde la consola de Firebase al target Runner si querés FCM estable en iOS.
- En Xcode: **+ Capability** → **Push Notifications** (y si usás notificaciones en background según tu caso, **Background Modes** → Remote notifications).
- En Apple Developer: clave APNs y configuración en Firebase — proceso fuera del repo.

### Backend desde el iPhone

- `localhost` en el teléfono **no** es tu Mac.
- **Scripts listos:** en la carpeta del backend `ManejApp/`, ejecutá `pnpm run dev:demo` o `./scripts/start-demo-backend.sh` (detecta IP LAN, imprime URLs y verifica `/api/v1/config`). En el frontend: `./scripts/run-ios-demo.sh` (ver comentarios al inicio de cada script).
- Misma WiFi que el Mac, o túnel (ngrok) si el backend está expuesto por HTTPS.

## Comandos útiles

```bash
cd ManejApp-frontend
flutter pub get
cd ios && pod install && cd ..
flutter devices
flutter run --release -d <device_id>
# o compilar sin firma (CI):
flutter build ios --no-codesign
```

## Checklist rápido de ensayo en el teléfono

| Área | Qué probar |
|------|-------------|
| Google login | Iniciar sesión con Google; debe volver a la app con el URL scheme |
| Face ID | Ajustes / bloqueo biométrico si lo usás en el flujo |
| Push | Permiso de notificaciones; token registrado (requiere Firebase + APNs bien configurados) |
| Reservas | Flujo alumno: buscar → reservar → ver en Mis reservas |
| Pagos | Sandbox Mercado Pago según entorno |
| Chat | Mensajes con instructor cuando la política lo permita |
| Navegación | Tabs alumno/instructor, atrás, deep link si aplica |
