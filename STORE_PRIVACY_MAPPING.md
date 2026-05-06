# Mapeo de privacidad para tiendas — App Privacy & Data Safety

**Propósito:** guía práctica para completar **Apple App Privacy** y **Google Play Data Safety** sin adivinar: cada fila enlaza al inventario técnico real.

**No es asesoría legal.** Las columnas “Qué marcar” son **propuestas** derivadas del código; **legal** debe validar texto público y declaraciones regulatorias.

**Referencias:**  
- `DATA_AND_SDK_INVENTORY.md` (incluye **validación manifest Android release**)  
- `PRIVACY_POLICY_DRAFT.md`  
- `ACCOUNT_DELETION_POLICY.md`  
- `SIWA_CLOSURE_CHECKLIST.md` (cierre operativo SIWA)  

---

## 1. Cómo usar este documento

1. Abrir **App Store Connect → App Privacy** y **Play Console → App content → Data safety**.  
2. Completar **Data Safety (Android)** usando el cierre operativo al final de este documento (**§8**). Completar **App Privacy (iOS)** con **§3** y la parte iOS de **§8**.  
3. Usar **§2** como tabla maestra de datos de negocio (backend + app). **Android e iOS difieren** en Firebase: no copiar declaraciones entre tiendas sin filtrar plataforma.

---

## 2. Tabla maestra (datos ↔ tiendas)

Leyenda **Recolecta:** según definición de cada tienda (usualmente incluye datos enviados al servidor operador o SDK).

| Categoría de dato | ¿En el repo / backend? | Uso principal | ¿Opcional? | Compartido con terceros | App Privacy (Apple) — tipo habitual | Data Safety (Google) — tipo habitual | Observaciones / evidencia |
|-------------------|------------------------|---------------|------------|-------------------------|--------------------------------------|----------------------------------------|---------------------------|
| Nombre | Sí | Cuenta, perfil | No para cuenta | No directo salvo OAuth | Name | Personal info (Name) | Google Sign-In devuelve nombre si aplica |
| Email | Sí | Cuenta, login, verificación | No | SMTP/Google Mail infra | Email address | Personal info (Email) | |
| Teléfono | Sí (opcional) | Contacto | Sí | No | Phone number | Personal info (Phone) | `User.phoneNumber` |
| DNI / ID nacional | Sí | Cuenta (único) | No | No | **Revisar con legal:** puede tratarse como identificación oficial | Personal info / Govt ID per Play taxonomy | Alta sensibilidad |
| Fecha de nacimiento | Sí | Cuenta/edad | No | No | Date of birth | Personal info | |
| Contraseña | Sí (hash servidor) | Auth | No | No | No suele declararse como “coleccionada” por Apple igual que texto plano — seguir guía Apple | Credentials (password) — típicamente “coleccionado, cifrado” | Solo hash en BD |
| User ID interno | Sí | Auth | No | No | User ID | Device or other IDs | |
| Google ID (sub) | Sí si usa login Google | Auth | Alternativa a password | Google | **Third-party account** / Linked third-party | Account info | Se elimina en anonimización de cuenta |
| Apple ID (`sub` → `appleSub`) | Sí si usa SIWA en iOS | Auth | Alternativa a password | Apple (flujo de identidad; datos operados según política Apple) | **Third-party account** / Identifiers / Email — **legal asigna categorías exactas** | N/A en Play para este SDK nativo Apple | Email relay posible; nombre solo primer login típico |
| Ubicación aproximada/precisa | Parcial | Mapa / instructores | Depende flujo | Google Maps | Location (precise/coarse) | Location | `geolocator` + permiso iOS; instructor lat/lng en BD |
| Fotos / archivos usuario | Sí | Perfil, docs instructor | Parcial | No en servidor propio | Photos / Other user content | Photos / Files and docs | `image_picker`, `file_picker` |
| Mensajes | Sí | Chat | Uso voluntario del chat | No | Messages / Other content | Messages | Anonimización en borrado cuenta |
| Historial reservas | Sí | Servicio | N/A | No | Other diagnostic (o “Other”) — ver taxonomía | App activity | `DrivingClass`, `ScheduleSlot` |
| Información de pago | Parcial | Pagos | Para pagar | **Sí — Mercado Pago** | Purchase history / Payment info per Apple guidelines | Financial info / Purchase history | MP procesa datos de pago |
| Identificadores de pago MP | Sí | Conciliación | N/A | Mercado Pago | Other | Financial info | IDs en `Payment` |
| Push token FCM | Backend sí; Android SDK empaquetado | Notificaciones | Típicamente sí | Google (Firebase) | Device ID / Other | Device or other IDs | **Android:** declarar FCM. **iOS:** sin Firebase pod — no por este canal salvo cambio futuro |
| Datos de uso / Analytics | **Android: sí (SDK Measurement)** | Producto / diagnóstico | N/A | **Sí — Google** | Analytics | App activity / App info and performance | **iOS:** sin Firebase cliente en lockfile — Maps/Sign-In pueden tener telemetría propia (revisar Google) |
| Registro fallos | No Crashlytics en deps listadas | — | — | — | Crash data si se activa otro SDK | — | Declarar solo si existe en binario |
| IP / User-Agent | Sí en sesiones | Seguridad | No opt-in típico | No | Other data types | Device or other IDs / Diagnostics | `Session.ip`, `userAgent` |

---

## 3. Apple App Privacy — checklist práctico

Resumen alineado con **§8.2**: **no** hay Firebase cliente en `Podfile.lock`; sí hay **Google Sign-In**, **Maps** y **Sign in with Apple** (solo iOS, binario actual).

**Sign in with Apple:** el binario iOS incluye el flujo (`sign_in_with_apple` + backend `/auth/apple`). El servidor persiste **`appleSub`** y los datos de perfil que envíe Apple en el token/primer login (típico: **email** verificado, **nombre/apellido** solo en el primer uso). En **App Privacy**, **legal** debe mapear esos tipos a las categorías y preguntas vigentes en App Store Connect (pueden incluir identificadores de cuenta / datos de contacto vinculados al usuario).

**Google Sign-In:** declarar datos típicos de cuenta (nombre, email, identificador).

**Tracking / ATT:** sin SDK de ads auditado; **legal** revisa Maps / Google utilities vs definición de “tracking” de Apple.

**Privacy Nutrition Labels sugeridos — iOS (pendiente validación legal):**

| Apple category | Data types | Linked to user | Used for tracking | Third-party SDK |
|----------------|------------|----------------|-------------------|-----------------|
| Contact Info | Name, Email, Phone | Yes | No* | Google Sign-In; datos que Apple expone en SIWA (email/nombre según caso) |
| Identifiers | User ID | Yes | No | — |
| Location | Coarse/Precise | Yes | No* | Maps / app logic |
| User Content | Photos, Messages | Yes | No | — |
| Purchases | Purchase history | Yes | No | Mercado Pago flow |

\* Legal confirma.

**Account deletion:** flujo en app + `ACCOUNT_DELETION_POLICY.md`; completar URL en App Store Connect.

---

## 4. Google Play Data Safety — checklist práctico

**Usar §8.1 como fuente principal.** Los puntos condicionales (“si Analytics está activo”) quedan **cerrados para Android release**: Measurement + FCM están en el manifest fusionado.

**Advertising ID:** manifest incluye permisos AD_ID — completar las preguntas específicas del formulario Play sobre IDs de publicidad.

**FCM:** SDK presente; verificar con red/backend si el token llega al servidor antes de afirmar funcionalidad al usuario.

---

## 5. Evidencia en el proyecto (para auditoría interna)

| Declaración sugerida | Evidencia repo |
|---------------------|----------------|
| Login Google | `google_sign_in` pubspec; backend `google-auth-library`; `GOOGLE_CLIENT_ID`; `Info.plist` `GIDClientID` |
| Maps | `google_maps_flutter`; `GMSApiKey`; Android `com.google.android.geo.API_KEY` |
| Pagos MP | `mercadopago` backend; rutas payments; `Payment.provider` |
| Push (servidor) | `firebase-admin`; `NotificationToken`; `notifications/service.ts` |
| Push / Analytics (Android cliente) | Manifest fusionado release (`build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`) + Gradle `firebase-analytics` / `firebase-messaging` |
| Push (Dart) | `notification_service.dart` stub |
| Sin Firebase iOS cliente | `ios/Podfile.lock` |
| Email transaccional | `nodemailer` + Gmail en `EmailService.ts` |
| Login Apple (SIWA) iOS | `sign_in_with_apple`; `POST /auth/apple`; `Runner.entitlements`; `APPLE_CLIENT_ID`; `SIWA_CLOSURE_CHECKLIST.md` |

## 6. Dudas que debe cerrar legal / producto

1. Texto exacto de **finalidad legal** y base jurídica por jurisdicción (AR, LATAM, UE si aplica).  
2. Si **DNI** se declara como “government ID” y cómo reducir minimización.  
3. Política de **retención** numérica (meses/años) por tipo de dato.  
4. Lista oficial de **subencargados** y DPA.  
5. **SIWA — App Privacy:** completar formulario según datos reales persistidos (`appleSub`, email, nombre); revisar coherencia con política pública — guía `SIWA_CLOSURE_CHECKLIST.md`.
6. **Data Safety — “compartido” vs “recopilado”** con Google (Analytics, FCM, Maps) según definiciones del formulario Play.  
7. **Maps SDK** — telemetría según términos Google; texto en política pública.

---

## 7. Siguiente paso recomendado

1. Si producto **no** quiere Analytics: quitar `firebase-analytics` / revisar BOM, rebuild y regenerar manifest (Ticket técnico aparte).  
2. **Wireshark / proxy / Play pre-launch report** opcional para confirmar eventos de red (no ejecutado en esta sesión).  
3. Publicar URL de política y completar formularios con **§8** + **§2**.

---

## 8. Cierre operativo — validación manifest Android release

Esta sección resume lo validado con `./gradlew :app:processReleaseMainManifest` y dependencias `releaseRuntimeClasspath`. Manifest de referencia:  
`ManejApp-frontend/build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`.

### 8.1 Google Play — Data Safety (orientación para completar el formulario)

**Premisa:** el **AAB/APK release de Android** analizado incluye **Firebase Analytics** (servicios `AppMeasurement*`), **Firebase Cloud Messaging** (`FirebaseMessagingService`, receptores), **FirebaseInitProvider**, y permisos **AD_ID** / Ad Services / install referrer. La cadena Gradle incluye `play-services-measurement` y dependencia explícita de **Advertising ID** para measurement.

| Pregunta típica Play | Respuesta técnica respaldada por repo + manifest |
|----------------------|--------------------------------------------------|
| ¿Se recopilan datos de **actividad de la app / analytics**? | **Sí (Android)** — SDK Measurement presente. Elegir categorías exactas del cuestionario (p. ej. “App activity”, “App info and performance”). |
| ¿Se usa **ID de publicidad**? | El binario declara permisos AD_ID / Ad Services; **asumir sí** para Measurement salvo desactivación documentada. Legal define “compartido” vs “solo en dispositivo”. |
| ¿Notificaciones push / mensajes? | **SDK FCM empaquetado (Android)**. Dart **no** llama a `saveFcmToken` hoy; no afirmar ausencia de FCM sin captura de red / verificación backend. |
| ¿Ubicación? | `GeolocatorLocationService` + Maps + datos en servidor — declarar según uso real en runtime. |
| ¿Datos financieros / pagos? | **Mercado Pago** — declarar según definición Play (compartido/procesado). |
| ¿Cifrado en tránsito? | Confirmar HTTPS en producción (operaciones). |

**No declarar como ausentes sin trabajo adicional:** Analytics Firebase, FCM, Advertising ID (Android).

### 8.2 Apple — App Privacy (orientación)

**Firebase Analytics / FCM en el cliente iOS:** `Podfile.lock` **no** lista pods Firebase. **No** reutilizar las mismas respuestas que Android para esos SDKs.

**Sí considerar en iOS:** Google Sign-In, Google Maps, **Sign in with Apple** (solo iOS), datos enviados al **propio backend** (tabla §2).

**ATT / Tracking:** legal revisa Maps/utilidades Google vs definición Apple.

**Sign in with Apple:** incluido en el binario iOS actual; actualizar **App Privacy** y política pública antes de release — `SIWA_CLOSURE_CHECKLIST.md`.

### 8.3 Asimetrías Android vs iOS

| Tema | Android (release validado) | iOS (`Podfile.lock`) |
|------|----------------------------|----------------------|
| Firebase Analytics cliente | **Incluido** | **No observado** |
| FCM cliente | **Incluido** | **No observado** |
| Google Sign-In | Sí | Sí |
| Sign in with Apple | No (no aplica Android store auth nativo Apple) | **Sí** (iOS; botón + backend) |
| Google Maps | Sí | Sí |
