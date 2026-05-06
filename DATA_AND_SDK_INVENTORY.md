# Inventario de datos y SDKs — ManejApp

**Propósito:** base técnica para Privacy Policy, App Privacy (Apple) y Data Safety (Google Play).  
**Método:** código del repo **más** validación de **build Android release** (Gradle + manifest fusionado).  
**No es asesoría legal.** Marcar dudas para revisión jurídica.

**Última validación binario/manifest:** `processReleaseMainManifest` + `releaseRuntimeClasspath` ejecutados sobre `ManejApp-frontend/android` (sesión de cierre Ticket 3). Manifest fusionado generado en  
`ManejApp-frontend/build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`.

**Documentos relacionados:** `PRIVACY_POLICY_DRAFT.md`, `STORE_PRIVACY_MAPPING.md`, `ACCOUNT_DELETION_POLICY.md`, `SIWA_AUDIT.md`, `SIWA_CLOSURE_CHECKLIST.md`.

---

## 1. Superficies del sistema

| Superficie | Tecnología | Rol respecto a datos |
|--------------|------------|----------------------|
| API backend | Express + Prisma (`ManejApp/`) | Recibe, persiste y procesa datos de usuarios; integra pagos, email, FCM vía Firebase Admin. |
| App móvil | Flutter (`ManejApp-frontend/`) | Captura datos del usuario; usa Maps, Sign-In, ubicación, cámara/archivos; HTTP al backend. |
| Panel admin | Next.js (`manejapp-admin/`) | Opera sobre la misma API con JWT en cookie; gestiona instructores, reportes, etc. |

---

## 2. Datos personales y sensibles (por categoría)

### 2.1 Identidad y cuenta

| Dato | Evidencia | Dónde se guarda |
|------|-----------|-----------------|
| Nombre, apellido | `User.name`, `User.surname` | BD (`prisma/schema.prisma`) |
| Email (único) | `User.email` | BD |
| DNI (único) | `User.dni` | BD |
| Contraseña (hash) | `User.password` | BD |
| Fecha de nacimiento | `User.birthDate` | BD |
| Rol | `User.role` (STUDENT / INSTRUCTOR / ADMIN) | BD |
| Estado cuenta | `User.isActive`, `User.accountDeletedAt` | BD |
| Verificación email | `emailVerificationToken`, `emailVerifiedAt` | BD |
| Google account link | `User.googleId` | BD |
| Apple Sign In (subject estable) | `User.appleSub` | BD (`@unique`, opcional) |
| IDs persistidos app | `userId`, tokens en `flutter_secure_storage` / sesión | Cliente (Flutter) |

**Sign in with Apple (iOS):** el cliente usa `sign_in_with_apple`; el backend valida `identityToken` (`POST /api/v1/auth/apple`) y persiste `appleSub`. No hay SDK Apple en Android para este flujo (botón solo iOS). Cierre operativo (Developer, Xcode, smoke device): `SIWA_CLOSURE_CHECKLIST.md`.

### 2.2 Contacto

| Dato | Evidencia | Notas |
|------|-----------|--------|
| Teléfono opcional | `User.phoneNumber` | Opcional en registro (`user.schema.ts`) |
| Email operativo | mismo que cuenta | Usado para verificación y recuperación (`EmailService.ts`) |

### 2.3 Ubicación

| Dato | Evidencia | Notas |
|------|-----------|--------|
| Dirección / texto ubicación usuario | `User.location` | Comentario en schema: geocoding en frontend |
| Instructor: lat, lng, geohash, texto dirección | `Instructor.lat`, `lng`, `geohash`, `addressText` | BD |
| Ubicación del dispositivo | `geolocator` + permisos iOS (`NSLocationWhenInUseUsageDescription` en `Info.plist`) | Solo cliente / envío al backend según pantallas que implementen |

### 2.4 Documentos sensibles (instructor)

| Dato | Evidencia |
|------|-----------|
| Rutas/archivos: doble comando, seguro, VTV, reincidencia, licencia | `Instructor.dobleComandoImg`, `seguroImg`, `vtvImg`, `reincidenciaImg`, `licenciaImg` |
| Estado revisión admin | `InstructorDocumentReview` |
| Número de licencia (opcional) | `Instructor.licenseNumber` |

Almacenamiento: servidor (`uploads/` según rutas de multer/FileService en backend).

### 2.5 Pagos y transacciones

| Dato | Evidencia |
|------|-----------|
| Monto, estado, método, proveedor | `Payment` model (`provider` default `mercadopago`) |
| Referencias externas MP | `paymentId`, `preferenceId`, `externalReference`, `idempotencyKey` |
| Payload webhook | `Payment.rawPayload` (Json) |
| Comisión / split | `appCommission`, `instructorAmount`, `commissionRate` |
| Datos MP instructor | `Instructor.mpCollectorId`, `mpAccessToken` |

**Tercero:** Mercado Pago procesa el pago; el backend usa SDK `mercadopago` y variables `MERCADOPAGO_*` (`config.ts`).

### 2.6 Mensajes / chats

| Dato | Evidencia |
|------|-----------|
| Conversaciones entre dos usuarios | `Conversation.participant1Id`, `participant2Id` |
| Mensajes: contenido, remitente, timestamps | `Message.content`, `senderId`, `sentAt`, `readAt` |

Tras borrado de cuenta (Ticket 2): contenido del remitente puede anonimizarse según `ACCOUNT_DELETION_POLICY.md`.

### 2.6bis Proveedores de login (cliente y API)

| Componente | Evidencia | Notas |
|------------|-----------|--------|
| Google Sign-In | `google_sign_in` en `pubspec.yaml` | iOS / Android / Web según pantalla |
| Sign in with Apple | `sign_in_with_apple` en `pubspec.yaml` | **Solo iOS** (botón en login/registro) |
| OAuth Google (API) | `POST /api/v1/auth/google` | |
| OAuth Apple (API) | `POST /api/v1/auth/apple`; `verifyAppleIdentityToken.ts` | `APPLE_CLIENT_ID` en env = Bundle ID iOS del binario |

### 2.7 Datos alumno / instructor (perfil negocio)

| Dato | Evidencia |
|------|-----------|
| Nivel experiencia alumno | `Student.experienceLevel` |
| Instructor: años experiencia, disponibilidad, validez, tarifa horaria, bio, categorías, fotos JSON, listado | `Instructor.*` en schema |
| Vehículos | `Car` (patente, marca, modelo, instructorId) |
| Reservas / clases | `DrivingClass`, `ScheduleSlot`, estados `BookingStatus` |
| Notas de clase | `DrivingClass.notes` |

### 2.8 Notificaciones push

| Dato | Evidencia |
|------|-----------|
| Token FCM por usuario | `NotificationToken` (1:1 `userId`) |
| Preferencias email/push | `User.emailNotifications`, `pushNotifications` |

Backend envía push vía **Firebase Admin** (`notifications/service.ts`, `firebase-admin`).

Cliente Flutter: `ApiService.saveFcmToken` existe; `NotificationService` es **stub** que no registra token (`notification_service.dart`). **Comportamiento Android release:** el manifest fusionado incluye `FirebaseMessagingService`, `FirebaseInstanceIdReceiver`, `FirebaseInitProvider` y transporte asociado — el **SDK FCM está empaquetado** y puede obtener/registrar token a nivel nativo aunque Dart no llame a `saveFcmToken`. **Práctica recomendada Data Safety:** declarar datos de mensajería push / identificadores asociados a FCM en **Android**, salvo que legal/producto demuestre lo contrario con pruebas de red.

### 2.9 Analytics / diagnósticos

| Componente | Evidencia |
|------------|-----------|
| **Firebase Analytics (Android release)** | Confirmado en **manifest fusionado**: `com.google.android.gms.measurement.AppMeasurementReceiver`, `AppMeasurementService`, `AppMeasurementJobService`; dependencias `firebase-analytics` → `play-services-measurement` (Gradle `releaseRuntimeClasspath`). |
| **Identificador de publicidad (Android)** | Manifest fusionado incluye `com.google.android.gms.permission.AD_ID`, `ACCESS_ADSERVICES_AD_ID`, `BIND_GET_INSTALL_REFERRER_SERVICE` — coherentes con cadena de dependencias de **Measurement** / Analytics. Declarar en **Data Safety** según definición Google (no es “opcional” ocultarlo si el binario lo incluye). |
| Firebase Messaging (Android release) | Manifest: servicios/receptores FCM listados arriba. |
| Archivo de proyecto Firebase Android | `android/app/google-services.json` presente en repo |
| **iOS** | `Podfile.lock` **no** lista pods `Firebase/Core`, `FirebaseAnalytics`, `FirebaseMessaging`, etc. La app iOS incluye **Google Maps** y **Google Sign-In** vía CocoaPods, pero **no** la pila Firebase cliente observable en lockfile actual. |
| Crashlytics | No aparece en dependencias Android/iOS revisadas ni en `pubspec.yaml`. |

No hay paquete Dart `firebase_analytics` / `firebase_core` / `firebase_messaging` en `pubspec.yaml`; la telemetría Android identificada es **nativa (Google Play services / Firebase)**.

### 2.9bis Validación Android release (resumen técnico)

Comandos útiles para repetir la auditoría:

```bash
cd ManejApp-frontend/android
./gradlew :app:processReleaseMainManifest
./gradlew :app:dependencies --configuration releaseRuntimeClasspath
```

**Hallazgos clave del manifest fusionado (además de Firebase):**

- Permisos: `POST_NOTIFICATIONS`, `WAKE_LOCK`, `com.google.android.c2dm.permission.RECEIVE`, biometría, **AD_ID** / Ad Services (véase §2.9).
- `GeolocatorLocationService` (foreground service tipo ubicación).
- Componentes **Google Sign-In** (SignInHubActivity, RevocationBoundService).
- **Meta-data Maps:** `com.google.android.geo.API_KEY` — valor incrustado en el binario; **riesgo operativo:** revisar restricciones (SHA-1, package) en Google Cloud y evitar exponer la clave en repositorios públicos.

**iOS:** comparación por `ios/Podfile.lock`: sin Firebase cliente; sí Maps + Sign-In (+ utilidades Google). La declaración en **App Privacy** para analytics/messaging tipo Firebase debe tratarse como **no aplicable por ese SDK** salvo que se añadan pods Firebase en una versión futura.

### 2.10 Identificadores persistentes y técnica

| Ítem | Evidencia |
|------|-----------|
| JWT access / refresh | Sesiones `Session` con `refreshHash`; cookies refresh en flujo web si aplica |
| IP / User-Agent sesión | `Session.ip`, `Session.userAgent` |
| Cookies admin | `js-cookie` + `admin_token` (`manejapp-admin/src/lib/api.ts`) |
| Deep links | Scheme `manejapp` (`AndroidManifest.xml`, `Info.plist`) |
| Logs servidor | `logs/` vía `LoggerConfig` / `ENABLE_FILE_LOGS` (`config.ts`) — riesgo de PII en payload si no se sanitiza |

### 2.11 Datos compartidos con terceros (resumen)

| Tercero | Qué se envía / procesa | Evidencia |
|---------|------------------------|-----------|
| Google (OAuth Sign-In) | Id token / perfil para login | `google-auth-library`, `GOOGLE_CLIENT_ID`, cliente iOS `GIDClientID` |
| Google Maps Platform | Mapas / places según uso en app | `google_maps_flutter`, API key Android/iOS |
| Mercado Pago | Pagos, preferencias, webhooks | `mercadopago`, rutas `/payments/mercadopago/*` |
| Google (Firebase) | **Android app:** Analytics + FCM empaquetados (manifest + Gradle). **Servidor:** envío FCM vía `firebase-admin`. **iOS app:** sin pods Firebase en `Podfile.lock` actual | `firebase-admin`; BOM Firebase en `build.gradle.kts`; manifest fusionado |
| Gmail / SMTP | Envío de emails transaccionales | `nodemailer` + `service: 'gmail'` (`EmailService.ts`) |

---

## 3. SDKs y dependencias relevantes

### 3.1 Flutter (`pubspec.yaml`)

- `google_maps_flutter`, `geolocator`
- `google_sign_in`, `google_sign_in_web`
- `image_picker`, `file_picker`
- `flutter_secure_storage`, `shared_preferences`
- `http`, `url_launcher`, `app_links`
- `local_auth` (biometría local)
- `google_fonts` (fuentes; conexión red a Google Fonts)

### 3.2 Backend (`package.json`)

- `mercadopago`, `google-auth-library`, `firebase-admin`, `nodemailer`
- `jsonwebtoken`, `cookie`, `bcrypt` / `bcryptjs`
- `@prisma/client` (persistencia)

### 3.3 Admin (`manejapp-admin/package.json`)

- `axios`, `js-cookie`, Next.js — sin SDKs de mapas ni pagos en el bundle admin listado.

### 3.4 Permisos declarados (app)

- **Android (fuente + manifest fusionado release):** `INTERNET`, `ACCESS_NETWORK_STATE`; **además** `POST_NOTIFICATIONS`, `WAKE_LOCK`, C2DM, biometría, **AD_ID / Ad Services**, install referrer; servicio de ubicación en primer plano (`GeolocatorLocationService`). Ubicación fina no aparece como permiso explícito en el fragmento base del manifest de la app, pero el servicio de geolocator y el uso de Maps implican capacidad de ubicación según runtime — alinear con pantallas que llaman a `geolocator`.
- **iOS:** ubicación when-in-use, fototeca, cámara, Face ID, claves Maps y Google Sign-In (`Info.plist`).

---

## 4. Riesgos y dudas abiertas

1. **Firebase Analytics (Android):** **cerrado a nivel “¿está en el binario?”** — sí (servicios Measurement en manifest). **Abierto para legal/producto:** si se desea **desactivar** telemetría, hace falta configuración explícita (p. ej. retirar dependencia / deshabilitar recolección según documentación Firebase Google) y **re-ejecutar** esta validación.
2. **FCM token → backend:** servidor y modelo listos; Dart no envía token — **verificar tráfico real** (¿el token nativo se registra en API sin código Dart?). Hasta aclararlo, **Data Safety** no debería afirmar “no recolectamos token” en Android.
3. **Google Maps SDK (iOS/Android):** puede implicar comunicación con servidores Google además de renderizado de mapas — **revisar** declaraciones “solo ubicación” vs telemetría del SDK en documentación Google y con legal.
4. **`Payment.rawPayload`:** puede contener datos personales de MP — minimización y retención para legal.
5. **Logs de servidor:** riesgo de PII; política de retención (`LOG_RETENTION_DAYS`) vs acceso.
6. **`google-services.json` / clave Maps en APK:** revisar práctica de secretos y restricciones en consola Google.
7. **Sign in with Apple:** implementado en código; **pendiente** validación en dispositivo real y actualización **App Privacy** / política publicada — `SIWA_CLOSURE_CHECKLIST.md`.
8. **Email “soporte” en plantillas HTML:** `soporte@manejapp.com` en `EmailService.ts` — validar canal oficial.

---

## 5. Referencias de archivo (auditoría)

- Modelo datos: `ManejApp/prisma/schema.prisma`
- Config env: `ManejApp/src/config/config.ts`, `ManejApp/.env.example`
- Pagos: `ManejApp/src/modules/payments/*`
- Notificaciones: `ManejApp/src/modules/notifications/service.ts`, `ManejApp/src/config/firebase.ts`
- Auth Google / Apple: `ManejApp/src/modules/auth/auth.services.ts`, `auth.routes.ts`; JWKS Apple: `ManejApp/src/shared/utils/verifyAppleIdentityToken.ts`
- Email: `ManejApp/src/shared/services/EmailService.ts`
- Flutter deps: `ManejApp-frontend/pubspec.yaml`
- Android Firebase: `ManejApp-frontend/android/app/build.gradle.kts`, `google-services.json`
- iOS permisos: `ManejApp-frontend/ios/Runner/Info.plist`
- Stub notificaciones Flutter: `ManejApp-frontend/lib/services/notification_service.dart`
- Borrado cuenta: `ManejApp/ACCOUNT_DELETION_POLICY.md`
- Manifest fusionado Android release: `ManejApp-frontend/build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml` (regenerar con `./gradlew :app:processReleaseMainManifest`)
- Pods iOS resueltos: `ManejApp-frontend/ios/Podfile.lock`
