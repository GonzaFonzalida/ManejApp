# Task 1 — Diagnóstico: registro/rol y 409

## Archivos involucrados

| Path | Rol |
|------|-----|
| `lib/screens/register_screen.dart` | Formulario email/password; llama `ApiService.register()` en `_submit()`; navega a `ChooseRoleScreen` o `EmailVerificationPendingScreen`. |
| `lib/screens/choose_role_screen.dart` | "Elegí tu rol"; llama `ApiService.completeRegistration(userId, role, ...)` (POST `/instructors/register`); navega a Home o Login. |
| `lib/services/api_service.dart` | `register()` → POST `/users/register` (con `ConnectivityService.postWithRetry`). `completeRegistration()` → POST `/instructors/register` (sin retry). |
| `lib/services/connectivity_service.dart` | `postWithRetry`: hasta 3 intentos ante `ClientException`/`Exception`; **no** distingue 4xx/5xx. |
| `lib/widgets/google_sign_in_button_web.dart` | En `initState`: listener `onCurrentUserChanged` + `signInSilently()` a los 500 ms; llama `ApiService.loginWithGoogle(idToken)` (POST `/auth/google`), **no** llama `register()`. |
| `lib/controllers/login_controller.dart` | `loginWithGoogle()` → `ApiService.loginWithGoogle()`; no llama `register()`. |

## Flujo actual (breve)

1. **Registro email/password**  
   Usuario en `RegisterScreen` → tap "Registrarse" → `_submit()` → `setState(_isLoading = true)` → `ApiService.register(...)` (POST `/users/register` con `postWithRetry`) → 201: guarda `user_id`, `auth_token`/`temp_*`, navega a `ChooseRoleScreen(userId)` o `EmailVerificationPendingScreen`.  
   Si respuesta ≠ 201: `register()` lanza `Exception(message)` → catch en `_submit()` muestra SnackBar, `finally` hace `_isLoading = false`.

2. **Elegir rol**  
   Usuario en `ChooseRoleScreen` → tap "Completar Registro" → `_submitRole()` → `_isLoading = true` → `ApiService.completeRegistration(userId, role, ...)` (POST `/instructors/register`) → éxito: si hay `auth_token` navega a Home; si no, intenta login con `temp_email`/`temp_password` y navega.  
   Si `completeRegistration` lanza: catch muestra SnackBar, `finally` hace `_isLoading = false`.

3. **Google (web)**  
   Al montar el botón: `signInSilently()` a los 500 ms → si hay sesión, `onCurrentUserChanged` → `loginWithGoogle(idToken)` → `onSuccess()` → `_handleGoogleLoginSuccess` (getMe + navegación). No se llama a `users/register` en este flujo.

## Dónde se queda “loading”

- **Variable/estado:** `_isLoading` en `RegisterScreen` o `_isLoading` en `ChooseRoleScreen`.
- **Escenario típico:**  
  - **RegisterScreen:** doble tap en "Registrarse" → dos llamadas a `register()`. La primera devuelve 201 y hace `pushReplacementNamed` a `ChooseRoleScreen`. La segunda devuelve 409 y lanza en el segundo `_submit()`. El catch/finally del segundo `_submit()` ejecutan `setState` en un `RegisterScreen` que ya puede estar desmontado → riesgo de `setState() called after dispose()` y comportamiento raro.  
  - **ChooseRoleScreen:** si `completeRegistration()` cuelga (sin respuesta) o si hay un path donde no se llega al `finally`, `_isLoading` queda en `true`.

## Por qué aparece 409 en `/users/register`

- **Doble envío desde RegisterScreen:** dos taps rápidos en "Registrarse" antes de que el primer `setState(_isLoading = true)` pinte el `CircularProgressIndicator`, así que dos `_submit()` llaman a `ApiService.register()`. La primera crea el usuario (201); la segunda recibe 409 (email/dni ya existente).
- **Retry de `postWithRetry`:** si la primera petición lanza (timeout/red) pero el backend ya creó el usuario (201), el reintento puede devolver 409. En ese caso `register()` lanza y el usuario ve error en RegisterScreen.

## Manejo actual del 409

- En `api_service.dart`, `register()` solo trata 201 como éxito. Cualquier otro status (incluido 409) hace `throw Exception(message)`. No hay lógica de “usuario ya existe”.
- En `register_screen.dart` el catch muestra el mensaje en SnackBar y en `finally` se hace `_isLoading = false`. No hay navegación a login ni mensaje específico para “ya existe”.

## Conclusión Task 1

- El 409 en `/users/register` viene de **doble submit** (doble tap) o de **retry** tras un 201 que no llegó a tiempo.
- El “loading infinito” puede deberse a **setState después de dispose** en RegisterScreen (segundo `_submit`) o a que en algún path de ChooseRoleScreen no se garantice `_isLoading = false`.
- No hay manejo explícito de 409 (idempotencia / “usuario ya existe” / continuar a login).
