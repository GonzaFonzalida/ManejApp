# Sign in with Apple — Auditoría y decisión formal

**Ticket:** P0 — Auditoría Sign in with Apple y cumplimiento App Store  
**Fecha:** 2026-04-30  
**Alcance:** decisión formal y plan técnico. El **estado del código tras la implementación** está resumido en **§9** (actualización posterior a la auditoría inicial).

---

## 1. Estado actual del login

### 1.1 App móvil Flutter (iOS / Android)

| Método | ¿Implementado? | Evidencia |
|--------|----------------|-----------|
| Email + contraseña (login) | Sí | [`ManejApp-frontend/lib/screens/login_screen.dart`](ManejApp-frontend/lib/screens/login_screen.dart): formulario email/contraseña, envío vía `LoginController.submit` → `ApiService.login`. |
| Email + contraseña (registro) | Sí | [`ManejApp-frontend/lib/screens/register_screen.dart`](ManejApp-frontend/lib/screens/register_screen.dart): `_submit` → `ApiService.register`. |
| Google Sign-In (nativo iOS/Android) | Sí | Login: [`login_screen.dart`](ManejApp-frontend/lib/screens/login_screen.dart) — rama no-web `AppButton` “Continuar con Google” → `controller.loginWithGoogle`. Registro: mismo archivo register — “Continuar con Google” → `_loginWithGoogle` → `GoogleAuthHelper.signIn`. |
| Google Sign-In (Web) | Sí | [`login_screen.dart`](ManejApp-frontend/lib/screens/login_screen.dart): si `kIsWeb`, usa `buildGoogleSignInButton` ([`google_sign_in_button.dart`](ManejApp-frontend/lib/widgets/google_sign_in_button.dart)). |
| Sign in with Apple | **Sí (solo iOS)** | Dependencia `sign_in_with_apple`; [`apple_auth_helper.dart`](ManejApp-frontend/lib/utils/apple_auth_helper.dart); botones en [`login_screen.dart`](ManejApp-frontend/lib/screens/login_screen.dart) / [`register_screen.dart`](ManejApp-frontend/lib/screens/register_screen.dart); [`Runner.entitlements`](ManejApp-frontend/ios/Runner/Runner.entitlements) con capability. Detalle de cierre operativo: [`SIWA_CLOSURE_CHECKLIST.md`](SIWA_CLOSURE_CHECKLIST.md). |
| Otros proveedores sociales (Facebook, Microsoft, Twitter, GitHub, etc.) | No | Búsqueda en frontend/backend sin integraciones reales de esos SDKs para login. |

### 1.2 Flujo técnico Google (referencia)

- [`ManejApp-frontend/lib/utils/google_auth_helper.dart`](ManejApp-frontend/lib/utils/google_auth_helper.dart): `GoogleSignIn`, obtiene `idToken`, llama `ApiService.loginWithGoogle(idToken)`.
- Login por contraseña y Google comparten post-login vía `RoleRouter` / `navigateAfterLogin` ([`login_controller.dart`](ManejApp-frontend/lib/controllers/login_controller.dart)).

### 1.2bis Flujo técnico Apple (referencia)

- [`ManejApp-frontend/lib/utils/apple_auth_helper.dart`](ManejApp-frontend/lib/utils/apple_auth_helper.dart): nonce SHA-256, `SignInWithApple.getAppleIDCredential`, `ApiService.loginWithApple`.
- [`ManejApp/src/modules/auth/auth.services.ts`](ManejApp/src/modules/auth/auth.services.ts): validación JWT con JWKS Apple (`verifyAppleIdentityToken.ts`), persistencia `appleSub`, misma emisión de sesión que Google.

### 1.3 Backend

| Endpoint | Rol |
|----------|-----|
| `POST /api/v1/auth/login` | Email/contraseña |
| `POST /api/v1/auth/google` | Google (`idToken` en body, validado en servicio) |
| `POST /api/v1/auth/apple` | Sign in with Apple (`identityToken`, `rawNonce`, nombres opcionales); `aud` = `APPLE_CLIENT_ID` (Bundle ID iOS) |

Evidencia: [`ManejApp/src/modules/auth/auth.routes.ts`](ManejApp/src/modules/auth/auth.routes.ts) — rutas `login`, `google`, `apple`.

---

## 2. Métodos de login en iOS y dónde aparece Google Sign-In

En **iOS**, la app Flutter usa los mismos screens que Android (no hay bifurcación por plataforma para ocultar Google en iOS).

### 2.1 Pantalla Login (`LoginScreen`)

- **Email/contraseña:** card principal con `AppInput` + botón “Ingresar”.
- **Google:** después del divisor “o continuá con”, botón **“Continuar con Google”** (no-web: `AppButton` → `loginWithGoogle`).
- **Roles:** no cambia por rol en esta pantalla; el usuario ya existe o entra y `RoleRouter` resuelve destino.

Archivo: [`ManejApp-frontend/lib/screens/login_screen.dart`](ManejApp-frontend/lib/screens/login_screen.dart).

### 2.2 Pantalla Registro (`RegisterScreen`)

- **Registro manual:** formulario completo + “Crear cuenta”.
- **Google:** divisor “o registrate con” + **“Continuar con Google”** → `_loginWithGoogle` → `GoogleAuthHelper.signIn`.

Archivo: [`ManejApp-frontend/lib/screens/register_screen.dart`](ManejApp-frontend/lib/screens/register_screen.dart).

### 2.3 Configuración nativa iOS para Google

- [`ManejApp-frontend/ios/Runner/Info.plist`](ManejApp-frontend/ios/Runner/Info.plist): `GIDClientID`, `CFBundleURLTypes` con schemes desde xcconfig (`GOOGLE_SIGN_IN_IOS_URL_SCHEME`, `manejapp`).
- Documentación de demo física: [`ManejApp-frontend/docs/IPHONE_DEMO_CHECKLIST.md`](ManejApp-frontend/docs/IPHONE_DEMO_CHECKLIST.md) (Google Sign-In en dispositivo).

---

## 3. ¿Aplica Sign in with Apple? — App Store Review Guideline 4.8

### 3.1 Hechos del producto

1. La app **ofrece un servicio de login de terceros** (Google) para iniciar sesión / registrarse en flujo equivalente al usuario final.
2. La app **no es** exclusivamente “solo cuenta corporativa del cliente”, ni “solo login del proveedor educativo institucional”, ni otro caso típico cubierto por las **excepciones** descritas en la guía (p. ej. 4.8.3 — uso limitado a datos empresariales del propio empleador, educación gestionada por institución, etc.).
3. ManejApp es una **app de consumo** (estudiantes/instructores): encaja en el escenario donde Apple suele exigir **Sign in with Apple** cuando hay login social de terceros.

### 3.2 Conclusión de aplicabilidad

Según la política típica reflejada en **App Store Review Guidelines — Guideline 4.8 (Login Services)**:

- Si la app usa **third-party login** (Google) para crear cuenta o iniciar sesión, debe ofrecer también una opción equivalente que cumpla privacidad según Apple; la vía estándar es **Sign in with Apple**, salvo que aplique una excepción explícita de la guía.

**No hay evidencia en el código ni en el modelo de negocio documentado en repo de que ManejApp califique para las excepciones de 4.8.3.**

Por tanto, desde auditoría de producto + código:

---

## 4. Decisión formal

### **SÍ APLICA implementar Sign in with Apple** para cumplir App Store Review Guideline 4.8 en la versión iOS que publica login con Google.

**Justificación trazable:**

- Google Sign-In está **presente en iOS** en login y registro (mismas pantallas Flutter que en Android).
- No existe Sign in with Apple ni login alternativo “equivalente” exigido por Apple más allá de email/contraseña **junto** al botón Google; la guía trata específicamente la combinación **social third-party + obligación de opción equivalente** (SIWA es el camino habitual de cumplimiento).
- El backend solo soporta Google como OAuth adicional; no hay Apple.

**Nota:** La **aprobación final** la otorga Apple en revisión. Este documento documenta **riesgo de rechazo** y **deber de ingeniería/compliance** según política publicada. Si el equipo legal considera una excepción muy concreta no reflejada aquí, debe **añadirse anexo legal** y citarse versión/fecha de la guía consultada.

---

## 5. Plan técnico de implementación (siguiente fase de trabajo)

### 5.1 Mobile (Flutter, botón solo iOS)

| Paso | Acción | Archivos / sistemas probables |
|------|--------|-------------------------------|
| 1 | Añadir dependencia `sign_in_with_apple` | [`ManejApp-frontend/pubspec.yaml`](ManejApp-frontend/pubspec.yaml), `pod install` |
| 2 | Helper `AppleAuthHelper` (nonce, credential, llamada API) | Nuevo: `ManejApp-frontend/lib/utils/apple_auth_helper.dart`; patrón [`google_auth_helper.dart`](ManejApp-frontend/lib/utils/google_auth_helper.dart) |
| 3 | `ApiService.loginWithApple(...)` | [`ManejApp-frontend/lib/services/api_service.dart`](ManejApp-frontend/lib/services/api_service.dart) |
| 4 | UI login/registro: botón “Continuar con Apple” solo `Platform.isIOS`, mismo peso visual que Google (HIG) | [`login_screen.dart`](ManejApp-frontend/lib/screens/login_screen.dart), [`register_screen.dart`](ManejApp-frontend/lib/screens/register_screen.dart) |
| 5 | Capability Sign in with Apple | [`Runner.entitlements`](ManejApp-frontend/ios/Runner/Runner.entitlements), Xcode, Apple Developer → App ID |
| 6 | Opcional Web/Android | SIWA no suele ser obligatorio fuera de iOS para esta guía; mantener alcance iOS primero |

### 5.2 Backend

| Paso | Acción | Archivos probables |
|------|--------|-------------------|
| 1 | `POST /api/v1/auth/apple` con rate limit | [`auth.routes.ts`](ManejApp/src/modules/auth/auth.routes.ts) |
| 2 | Schema Zod body (identityToken, authorizationCode opcional, nonce, user names opcional primer login) | [`auth.schemas.ts`](ManejApp/src/modules/auth/auth.schemas.ts) |
| 3 | Controller + Service: verificar JWT Apple (JWKS `https://appleid.apple.com/auth/keys`), `iss`, `aud` = bundle id, `exp`, extraer `sub` | [`auth.controller.ts`](ManejApp/src/modules/auth/auth.controller.ts), [`auth.services.ts`](ManejApp/src/modules/auth/auth.services.ts) |
| 4 | Modelo usuario: campo único opcional `appleSub` (o tabla identity) | [`prisma/schema.prisma`](ManejApp/prisma/schema.prisma), migración |
| 5 | Crear usuario o login por `sub`; manejar relay email y ausencia de email en logins posteriores | Misma capa que `googleLogin` |
| 6 | Misma emisión de JWT/cookies que login Google | Reutilizar flujo existente post-validación |

### 5.3 Compliance relacionado (otros tickets)

- **Account deletion (P0):** al implementar borrado de cuenta, incluir limpieza de `appleSub` y sesiones.
- **App Privacy:** declarar identificador Apple / cuenta Apple según lo que se persista.
- **Apple Developer:** habilitar Sign in with Apple en el App ID; regenerar perfiles si hace falta.

### 5.4 Dependencias externas

- Cuenta Apple Developer con App ID de [`IPHONE_DEMO_CHECKLIST.md`](ManejApp-frontend/docs/IPHONE_DEMO_CHECKLIST.md) / proyecto (`com.gonzalofonzalida.manejapp` según checklist).
- Secreto/clave si el backend valida tokens con estrategia que lo requiera (documentar en `.env`, sin commitear valores).

---

## 6. Riesgos si no se implementa

| Riesgo | Impacto |
|--------|---------|
| Rechazo en App Store Review (Guideline 4.8) | Bloqueo de publicación iOS |
| Retrasos por revisiones iterativas | Costo de tiempo y repetición de builds |
| Inconsistencia legal/comercial vs políticas Apple | Riesgo reputacional |

---

## 7. Definition of Done (implementación futura)

La implementación de SIWA se considerará terminada cuando:

1. Este documento (`SIWA_AUDIT.md`) permanezca como **decisión formal** vigente (actualizar solo si cambia el alcance de login o la guía).
2. En **iOS**, pantallas **Login** y **Registro** muestren **“Continuar con Apple”** con jerarquía visual equivalente a Google según HIG.
3. Exist **`POST /api/v1/auth/apple`** que valide el `identityToken` de Apple y cree/inicie sesión con identidad estable (`sub` / `appleSub` en DB).
4. [`Runner.entitlements`](ManejApp-frontend/ios/Runner/Runner.entitlements) incluya capability **Sign in with Apple** y el proyecto firme correctamente.
5. **App Privacy** en App Store Connect actualizado respecto a datos de Apple ID.
6. **Account deletion** (ticket aparte) elimine o anonimice vínculos Apple.
7. **Smoke E2E manual:** primer login Apple (con email visible o relay), segundo login sin re-envío de nombre/email, logout, login de nuevo; sin regresión en Google ni email/contraseña.

**Checklist operativo para marcar “cerrado” en release:** [`SIWA_CLOSURE_CHECKLIST.md`](SIWA_CLOSURE_CHECKLIST.md).

---

## 8. Referencias cruzadas al release plan

- Plan maestro: [`RELEASE_MASTER_PLAN.md`](RELEASE_MASTER_PLAN.md)
- Plan de ejecución: [`RELEASE_EXECUTION_PLAN.md`](RELEASE_EXECUTION_PLAN.md) — Ticket 1 (SIWA audit) queda **cerrado en decisión** con este archivo; seguimiento de **implementación y cierre operativo**: §9 y `SIWA_CLOSURE_CHECKLIST.md`.

---

## 9. Actualización — implementación en repositorio

Resumen **solo de ingeniería** (no sustituye Apple Developer, App Privacy ni QA en dispositivo):

| Ítem §7 | Estado típico en repo |
|---------|-------------------------|
| Decisión formal §4 | Vigente |
| Botón SIWA login/registro iOS | Implementado |
| `POST /auth/apple` + `appleSub` | Implementado (Prisma + tests integración) |
| `Runner.entitlements` | Capability Sign In with Apple |
| Account deletion + Apple | `appleSub` anulado; sin contraseña si hay vínculo Apple |
| App Privacy App Store Connect | **Acción humana en consola** |
| Smoke E2E en iPhone | **QA manual** |

---

*Documento generado como entrega del Ticket P0 — Auditoría Sign in with Apple. La §9 describe el estado del código en repo tras la implementación; el cierre de release/compliance sigue `SIWA_CLOSURE_CHECKLIST.md`.*
