# QA Pre-Demo — ManejApp

**Matriz completa A–D, priorización, evidencia de comandos y checklist final:** [QA_PRE_DEMO_FINAL.md](QA_PRE_DEMO_FINAL.md) (fuente de verdad).

Documento vivo para presentación: cobertura automatizada, matriz de flujos, checklist manual y **evidencia de comandos** (última corrida documentada en esta sesión).

---

## 1. Resumen corto

- **Backend:** 52 tests Jest (integración + unit), SQLite dedicado, `maxWorkers: 1` para evitar carreras en DB de test.
- **Flutter:** 37 tests (`flutter test`), incluyendo sesión/refresh/reintento HTTP (VM), validación de login, ExploreIntent, ReservarClaseController, suites previas (RoleRouter, premium UI, mapa).
- **Integration (macOS):** 7 escenarios en `integration_test/premium_reservations_e2e_test.dart` contra mock HTTP local (ver [QA_PRE_DEMO_FINAL.md](QA_PRE_DEMO_FINAL.md)).
- **Correcciones bloqueantes detectadas al testear:** webhook Mercado Pago montado detrás de `authenticate`, validación/bind de rutas de mensajes, layout de carga en Mis pagos, filtro incorrecto alumno↔pagos, `getPayments` vs envelope del API, `Payment.fromJson` y `method`/`paymentMethod`.

---

## 2. Auditoría de cobertura actual

### Backend (`ManejApp/`)

| Tipo | Archivos | Contenido relevante |
|------|----------|---------------------|
| Integración | `tests/integration/auth.test.ts`, `users.test.ts`, `schedule.test.ts`, `booking-consistency.test.ts`, **`instructors.test.ts`**, **`messages.test.ts`**, **`payments.test.ts`** | Auth, usuarios, agenda, reservas/pagos premium, instructores HTTP, mensajes HTTP, pagos/listado/webhook/preference (autorización) |
| Unit | `tests/unit/instructorPublishable.test.ts`, `instructorUploadDocument.test.ts` | Publicabilidad instructor, upload base64 (mock fs) |
| Smoke | `tests/sanity.test.ts` | Smoke mínimo |
| **Sin tests HTTP dedicados típicos** | — | `admin`, `notifications`, `cars`, `permissions` (salvo uso cruzado) |

### Flutter (`ManejApp-frontend/`)

| Tipo | Archivos | Notas |
|------|----------|-------|
| Unit / lógica | `role_router_test.dart`, `student_profile_completion_test.dart`, `user_facing_error_test.dart`, `premium_booking_ui_test.dart`, `profile_map_marker_icon_service_test.dart`, **`search_explore_test.dart`**, **`reservar_clase_test.dart`** | Routing por rol, onboarding alumno, errores, copy premium, mapa |
| VM / red | **`auth_persistence_test.dart`** (`package:test`) | `SessionManager`, `AuthHttpClient` + `HttpServer` local (no `flutter_test` para no bloquear HTTP) |
| Widget | `widget_test.dart`, `google_map_screen_smoke_test.dart`, **`login_controller_test.dart`** | Arranque, mapa, validación formulario login |
| Integration | `integration_test/premium_reservations_e2e_test.dart` + `support/premium_e2e_mock_server.dart` | Reservas premium alumno/instructor + **Mis pagos** con mock |

### Docs QA existentes (backend)

- `ManejApp/docs/ROUTING_QA_CHECKLIST.md`
- `ManejApp/docs/QA_ENDPOINTS_VERIFICATION.md`
- `ManejApp/TESTING-SETUP.md`
- `ManejApp/scripts/qa-verify-endpoints.js`

---

## 3. Matriz de flujos críticos (automatizado vs manual)

Leyenda: **A** automático en CI/local · **P** parcial · **M** solo manual / dispositivo real

### A. Auth / sesión

| Flujo | Cobertura |
|-------|-----------|
| Registro email/password | **P** — API en Jest; UI registro sin tests dedicados |
| Login email/password | **P** — API Jest; validación formulario Login |
| Logout | **P** — `SessionManager.clearSession` + API logout en código |
| Sesión persistida / restart | **M** — ver checklist + `ROUTING_QA_CHECKLIST.md` |
| Refresh con token vencido | **A** — `AuthHttpClient` + `SessionManager.tryRefresh` (mock HTTP) |
| Google Sign-In | **M** — SDK real |
| Face ID / biometría | **M** — hardware |
| Expiración / redirect | **P** — RoleRouter unit; E2E app limitado |

### B. Alumno

| Flujo | Cobertura |
|-------|-----------|
| Onboarding / rol | **P** — RoleRouter + `student_profile_completion_test` |
| Home / explore mapa | **P** — smoke `GoogleMap`; sin E2E explore completo |
| Reserva / pago real MP | **M** — sandbox/prod MP |
| Mis reservas / detalle / cancelar | **A** — E2E mock + Jest booking |
| Mis pagos | **A** — E2E mock + fix filtro + `getPayments` envelope |
| Chat | **M** — backend messages cubierto; Flutter sin tests |
| Notificaciones push | **M** — APNs / FCM dispositivo |

### C. Instructor

| Flujo | Cobertura |
|-------|-----------|
| Registro instructor (HTTP) | **A** — `instructors.test.ts` |
| Hub / docs / perfil | **P** — routing unit; upload documento API test |
| Dashboard / clases | **P** — E2E lista/detalle instructor (mock) |

### D. Sistema / calidad

| Flujo | Cobertura |
|-------|-----------|
| Vacíos / errores UI | **P** — `humanizeApiError`, empty E2E reservas |
| Webhook MP | **A** — orden de routers + test HTTP 200 |
| Admin dashboard | **M** |

---

## 4. Tests nuevos agregados (esta entrega)

**Backend**

- `ManejApp/tests/integration/instructors.test.ts`
- `ManejApp/tests/integration/messages.test.ts`
- `ManejApp/tests/integration/payments.test.ts`

**Flutter**

- `ManejApp-frontend/test/auth_persistence_test.dart`
- `ManejApp-frontend/test/login_controller_test.dart`
- `ManejApp-frontend/test/search_explore_test.dart`
- `ManejApp-frontend/test/reservar_clase_test.dart`
- Caso extra en `integration_test/premium_reservations_e2e_test.dart`
- Rutas mock `GET /classes`, `GET /payments` en `integration_test/support/premium_e2e_mock_server.dart`

**Config**

- `ManejApp/jest.config.js` — `maxWorkers: 1`
- `ManejApp-frontend/pubspec.yaml` — `dev_dependencies: test: ^1.25.0`

---

## 5. Archivos modificados (bugs y contrato API)

- `ManejApp/src/app.ts` — orden `webhookRouter` antes de `functionalPaymentRoutes`
- `ManejApp/src/modules/messages/messages.schemas.ts` — body plano para `/send`; params para conversación
- `ManejApp/src/modules/messages/messages.routes.ts` — `validateParams` + `.bind()` en handlers
- `ManejApp-frontend/lib/screens/student_payments_screen.dart` — filtro clases/pagos; skeleton sin `ListView` anidado en `CustomScrollView`
- `ManejApp-frontend/lib/services/api_service.dart` — `getPayments` acepta lista o `{ data: [] }`
- `ManejApp-frontend/lib/models/payment.dart` — `method` o `paymentMethod`

---

## 6. Comandos ejecutados y resultados

Última corrida documentada: **2026-04-10** (misma sesión que cerró este documento).

| Comando | Carpeta | Resultado |
|---------|---------|-----------|
| `npx jest` | `ManejApp/` | **Exit 0** — `Test Suites: 10 passed`, `Tests: 52 passed`. Jest puede mostrar al final `Force exiting Jest: Have you considered using --detectOpenHandles` (manejar handles async si molesta en CI). |
| `flutter test` | `ManejApp-frontend/` | **Exit 0** — **37 tests** pasados (`All tests passed!`). |
| `flutter analyze` | `ManejApp-frontend/` | **Exit 1** — **38 issues** (mayoría `info` deprecations / `use_build_context_synchronously`; **2 warnings** en `profile_screen.dart` campos no usados). Incluye líneas en `api_service.dart` tocadas para envelope de pagos; no se limpió deuda global del repo en este QA. |
| `flutter test integration_test/premium_reservations_e2e_test.dart -d macos` | `ManejApp-frontend/` | **No finalizado en esta sesión:** build macOS **OK** (`✓ Built .../manejapp.app`); el primer caso (`alumno: Mis reservas → detalle → cancelar → listado vacío`) **no avanzó** tras varios minutos (posible bloqueo por entorno headless, permisos de app macOS o timeouts de integración). **Re-ejecutar en tu máquina** con ventana visible y documentar aquí el resumen (`+N: All tests passed!`). |

**Limitaciones**

- **Integration E2E:** requiere **macOS** con target `macos` y suele ser lento en cold build; en simulador iOS/Android `127.0.0.1` apunta al dispositivo, no al host (ajustar mock/base URL si se prueba ahí).
- **`flutter analyze`:** el proyecto **no queda en verde** con la configuración actual; el plan de demo asume revisión manual de issues heredados.

---

## 7. Checklist manual brutal (pre-demo)

### Alumno (iPhone real recomendado)

- [ ] Registro nuevo → verificación email si aplica → login
- [ ] Home / mapa: instructores cargan; ubicación; filtro nombre/zona
- [ ] Perfil instructor público → reservar slot → **PENDING_PAYMENT** → abrir MP (sandbox)
- [ ] Mis reservas → detalle → cancelar (ventana permitida)
- [ ] Mis pagos: lista coherente con clases del usuario (**probar tras fix**)
- [ ] Chat con instructor con clase pagada (si política lo exige)

### Instructor (iPhone real)

- [ ] Login → hub onboarding → subir documentos → perfil completo
- [ ] Dashboard → crear franja → alumno reserva
- [ ] Mis clases → detalle
- [ ] Notificaciones in-app / badge mensajes

### Sistema

- [ ] Matar backend: mensaje claro, sin loader infinito (`ROUTING_QA_CHECKLIST.md`)
- [ ] Pull-to-refresh en listas críticas
- [ ] Deep link desde notificación (si está configurado en build)

### Solo dispositivo real

- [ ] **Google Sign-In** (SDK + consent screen)
- [ ] **Face ID / Touch ID** (`local_auth`)
- [ ] **Push iOS** (APNs, permisos, token FCM en backend)
- [ ] **Crashlytics** (si está en el flavor de release): forzar crash de prueba en build interno y verificar en consola Firebase

---

## 8. Qué sigue dependiendo de humano / hardware

- Flujo completo **Mercado Pago** con tarjeta real o sandbox en dispositivo
- **Biometría** y **Google** en iOS/Android reales
- **Push** y apertura desde notificación
- **Carga** y revisión admin de documentos instructor
- Exploración **exploratory** de copy y edge cases de red lenta

---

## 9. Riesgos reales pendientes

- **JWT con rol desactualizado:** el middleware `authenticate` usa el rol del token; tras pasar a instructor hay que **volver a loguear** para endpoints `requireRole` (comportamiento conocido; los tests de instructor re-login explícito).
- **Admin / notificaciones / cars:** sin cobertura Jest dedicada
- **Flutter `getDrivingClasses` / otros endpoints:** siguen asumiendo JSON crudo en varios métodos; `getPayments` ya acepta envelope — revisar otros si el backend unifica `ResponseFormatter`
- **Analyze en verde:** no alcanzado a nivel repo completo (deuda previa)

---

## 10. Referencias rápidas de comando

```bash
# Backend
cd ManejApp && pnpm run build && npx jest

# Flutter
cd ManejApp-frontend && flutter pub get && flutter test && flutter analyze
# E2E (Mac)
cd ManejApp-frontend && flutter test integration_test/premium_reservations_e2e_test.dart -d macos
```
