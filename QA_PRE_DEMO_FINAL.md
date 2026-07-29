# QA Pre-Demo FINAL — ManejApp

Documento autoritativo para demo real: auditoría, matriz de flujos, tests añadidos, evidencia de comandos y checklist manual.  
**Fuente de verdad** frente a resúmenes cortos en `QA_PRE_DEMO.md`.

**Última actualización de evidencia:** 2026-04-11 (corrida en esta sesión).

---

## 1. Resumen corto

- **Backend:** contrato HTTP fuerte en auth, usuarios, agenda, reservas/pagos premium, instructores, mensajes y pagos; **sin** suites dedicadas típicas a admin, cars, permissions ni **listados de notificaciones para usuario** (el módulo notifications solo expone POST administrativos + registro de token).
- **Flutter:** tests de lógica (RoleRouter, onboarding, errores, explore/reservar, auth VM), smoke mapa/login, e **7 integration tests macOS** contra mock HTTP (`PremiumE2eMockServer`) incluyendo home alumno, mensajes vacío/error+retry, reservas, pagos e instructor.
- **Confianza máxima posible:** automatización cubre contratos y pantallas clave con mocks; **Google Sign-In, biometría, push real y Mercado Pago con SDK/tarjeta** siguen siendo **manuales en dispositivo**.
- **Analyze:** el proyecto **no** queda en verde global (deuda previa de lints); no es bloqueo de demo si no se tocan áreas críticas sin cubrir.

---

## 2. Auditoría de cobertura actual

### 2.1 Backend (`ManejApp/`)

| Archivo | Tipo | Qué valida |
|---------|------|------------|
| `tests/integration/auth.test.ts` | Integración HTTP | Login, refresh (body/cookie), logout, `/me`, rotación de sesión |
| `tests/integration/users.test.ts` | Integración HTTP | Registro estudiante, duplicados |
| `tests/integration/schedule.test.ts` | Integración HTTP | Slots, reserva, preview premium |
| `tests/integration/booking-consistency.test.ts` | Integración HTTP | Concurrencia, cancelaciones, webhook tardío, contrato premium por rol |
| `tests/integration/instructors.test.ts` | Integración HTTP | Registro instructor, nearby, perfil, listed, documentos |
| `tests/integration/messages.test.ts` | Integración HTTP | Envío/listados mensajes y conversaciones |
| `tests/integration/payments.test.ts` | Integración HTTP | Listado, preference, webhook, pago por clase |
| `tests/unit/instructorPublishable.test.ts` | Unit | Reglas de publicación |
| `tests/unit/instructorUploadDocument.test.ts` | Unit | Upload documento (mock fs) |
| `tests/sanity.test.ts` | Smoke | Smoke mínimo |

**Config:** `jest.config.js` — `maxWorkers: 1` (SQLite de test).

**Huecos relevantes demo:** HTTP directo **admin**, **notifications** (no hay GET de bandeja usuario; solo POST admin + token), **cars**, **permissions** como suites dedicadas.

### 2.2 Flutter (`ManejApp-frontend/`)

| Archivo / carpeta | Tipo | Qué valida |
|-------------------|------|------------|
| `test/role_router_test.dart` | Unit | Routing por rol y JWT vs DB |
| `test/student_profile_completion_test.dart` | Unit | Completitud de perfil alumno |
| `test/user_facing_error_test.dart` | Unit | Errores humanizados |
| `test/premium_booking_ui_test.dart` | Unit | Copy/UI premium |
| `test/search_explore_test.dart` | Unit | Intención explore / filtros |
| `test/reservar_clase_test.dart` | Unit | Controller reserva |
| `test/profile_map_marker_icon_service_test.dart` | Unit | Iconos mapa |
| `test/auth_persistence_test.dart` | VM (`package:test`) | Sesión, refresh con mock HTTP |
| `test/login_controller_test.dart` | Widget | Validación formulario login |
| `test/widget_test.dart`, `google_map_screen_smoke_test.dart` | Widget / smoke | Arranque, GoogleMap |
| `integration_test/premium_reservations_e2e_test.dart` | Integration | Ver sección 4 |

### 2.3 QA manual / docs existentes

- `ManejApp/docs/ROUTING_QA_CHECKLIST.md` — routing y backend caído  
- `ManejApp/docs/QA_ENDPOINTS_VERIFICATION.md` — verificación de endpoints  
- `ManejApp/TESTING-SETUP.md` — setup backend + cliente  
- `ManejApp/scripts/qa-verify-endpoints.js` — script Node

### 2.4 Huecos críticos y priorización

| Prioridad | Área | Motivo |
|-----------|------|--------|
| **P0** | Auth + reservas + pagos (API) | Ya cubierto en Jest + booking; riesgo bajo de contrato |
| **P1** | Flutter E2E con mock (home, mensajes, reservas) | Alta visibilidad en demo; **implementado** en esta entrega (ampliación mock + tests) |
| **P2** | Admin / notificaciones HTTP usuario | **Notificaciones:** sin GET list para usuario en API actual → no se añadió test de contrato vacío |
| **P3** | `flutter analyze` global | Deuda de estilo/deprecations; no bloquea demo funcional |

---

## 3. Matriz de flujos críticos (A–D)

Leyenda cobertura: **Sí** | **Parcial** | **No**  
Tipo ideal: **unit** | **widget** | **integration** | **manual** (dispositivo / humano)

### A. Auth / sesión

| Flujo | Rol | Precondición | Pasos / resultado esperado | Cobertura | Tipo ideal | Prioridad |
|-------|-----|--------------|----------------------------|-----------|------------|-----------|
| Registro email/password | — | Sin cuenta | Registrar → usuario creado | Parcial (API Jest; UI sin E2E dedicado) | integration + manual | Alta |
| Login email/password | — | Cuenta válida | Login → token | Parcial (API + validación form login) | integration | Alta |
| Logout | — | Sesión activa | Logout → limpieza local / revocación | Parcial (API Jest; VM `clearSession`) | integration + manual | Alta |
| App restart con sesión | Alumno/Inst. | Tokens guardados | Cold start → dashboard sin re-login | No (E2E real) | manual | Alta |
| Refresh con token vencido | — | Access inválido + refresh válido | Request → refresh → retry | Sí (`auth_persistence_test` + API Jest) | unit + integration | Alta |
| Google Sign-In | — | Cuenta Google | OAuth → sesión | No | manual | Alta |
| Face ID / biometría | — | Hardware | Desbloqueo → sesión | No | manual | Media |
| Expiración sesión | — | Refresh inválido | Redirect login | Parcial (RoleRouter) | unit + manual | Alta |

### B. Alumno

| Flujo | Rol | Precondición | Pasos / resultado esperado | Cobertura | Tipo ideal | Prioridad |
|-------|-----|--------------|----------------------------|-----------|------------|-----------|
| Registro + rol alumno | STUDENT | Email nuevo | Registro → rol STUDENT | Parcial (API) | integration | Alta |
| Onboarding progresivo | STUDENT | Perfil incompleto | Completar datos → 100% | Parcial (tests completitud + RoleRouter) | unit + manual | Media |
| Home alumno | STUDENT | Sesión + perfil | Inicio carga sin crash; CTA si sin reservas | Parcial (E2E mock home) | integration | Alta |
| Búsqueda instructores | STUDENT | — | Lista/empty según API | Parcial (`search_explore_test`) | unit + manual | Alta |
| Búsqueda por localidad | STUDENT | — | Filtro / zona | Parcial | unit + manual | Media |
| Mapa y cercanos | STUDENT | Ubicación | Mapa + marcadores | Parcial (smoke mapa) | widget + manual | Alta |
| Perfil instructor | STUDENT | — | Detalle público | Parcial | manual | Alta |
| Reserva de clase | STUDENT | Slot libre | Reserva → PENDING_PAYMENT / confirmada | Parcial (Jest + controller + E2E parcial) | integration + manual | Alta |
| Review / éxito | STUDENT | — | Pantalla éxito | Parcial (E2E mock) | integration | Media |
| Mis reservas / detalle / cancelar | STUDENT | Reserva | Lista → detalle → cancelar | Parcial (E2E mock) | integration | Alta |
| Pagos | STUDENT | Clase pendiente | Listado / MP | Parcial (API + E2E Mis pagos mock) | integration + manual MP | Alta |
| Chat | STUDENT | Pago/clase según política | Lista + mensajes | Parcial (API Jest; UI lista vacía + error E2E) | integration + manual | Alta |
| Notificaciones | STUDENT | Token APNs | Push / in-app | No automatizado | manual | Media |

### C. Instructor

| Flujo | Rol | Precondición | Pasos / resultado esperado | Cobertura | Tipo ideal | Prioridad |
|-------|-----|--------------|----------------------------|-----------|------------|-----------|
| Registro / login instructor | INSTRUCTOR | Flujo documentos | Hub → dashboard | Parcial (HTTP register + RoleRouter) | integration + manual | Alta |
| Hub onboarding / documentos | INSTRUCTOR | Sin docs | Subir y estado | Parcial (API + unit) | manual | Alta |
| Perfil completo | INSTRUCTOR | Datos | Publicable | Parcial (unit publishable) | unit + manual | Alta |
| Dashboard / horarios / clases | INSTRUCTOR | Cuenta válida | Listas y detalle | Parcial (E2E mock clases) | integration + manual | Alta |
| Chat | INSTRUCTOR | Conversación | Mensajes | Parcial (API) | manual | Media |
| Notificaciones | INSTRUCTOR | — | Push | No | manual | Media |

### D. Sistema / calidad

| Flujo | Rol | Precondición | Pasos / resultado esperado | Cobertura | Tipo ideal | Prioridad |
|-------|-----|--------------|----------------------------|-----------|------------|-----------|
| Empty states | Cualquiera | Sin datos | Copy y CTA | Parcial (E2E mock) | integration | Media |
| Errores / retry | Cualquiera | API falla | Mensaje + reintentar | Parcial (E2E mock mensajes) | integration | Alta |
| Pull-to-refresh | Cualquiera | Listas | Recarga | Parcial | manual | Media |
| Navegación crítica | Cualquiera | — | Tabs / rutas | Parcial (RoleRouter + E2E) | unit + manual | Alta |
| Deep links / notificación | Cualquiera | Configurado | Abrir pantalla | Parcial | manual | Baja |
| Crashlytics | Release | Firebase | Crash de prueba | No | manual | Baja |

---

## 4. Tests nuevos agregados (esta entrega)

**Integration (`integration_test/premium_reservations_e2e_test.dart`)**

1. **Alumno:** `StudentHomeDashboardScreen` con perfil mock completo y sin reservas → aparece `NextActionCard` con key `E2eKeys.studentHomeNoBookingsCard` y texto “Todavía no reservaste”.
2. **Alumno:** `ConversationsScreen` → lista vacía (“Todavía no tenés conversaciones”).
3. **Alumno:** `conversationsRespond500` → error → “Reintentar” → lista vacía.

**Mock (`integration_test/support/premium_e2e_mock_server.dart`)**

- `GET /api/v1/messages/conversations` y `GET /api/v1/messages/unread-count`.
- Flag `conversationsRespond500` para simular fallo HTTP.
- `GET /api/v1/users/7` → perfil alumno completo al 100% (`_e2eStudentProfileComplete`) para el home.

**UI / keys**

- `E2eKeys.conversationsRetry`, `E2eKeys.studentHomeNoBookingsCard`.
- `ConversationsScreen`: `retryButtonKey` en `AppErrorState`.
- `StudentHomeDashboardScreen`: `key` en `NextActionCard` “Todavía no reservaste”.

---

## 5. Archivos modificados

- `ManejApp-frontend/lib/keys/e2e_keys.dart`
- `ManejApp-frontend/lib/screens/conversations_screen.dart`
- `ManejApp-frontend/lib/screens/student_home_dashboard_screen.dart`
- `ManejApp-frontend/integration_test/support/premium_e2e_mock_server.dart`
- `ManejApp-frontend/integration_test/premium_reservations_e2e_test.dart`  
- `ManejApp-frontend/QA_PRE_DEMO.md` (enlace a este documento)

**Backend:** sin cambios de código en esta entrega. **Evaluación notifications:** no se añadió test de integración; el router solo expone endpoints POST (admin + token), no un listado GET para usuario final.

---

## 6–7. Comandos ejecutados y resultados

Ejecutados desde las rutas indicadas en **2026-04-11**.

| Comando | Directorio | Exit | Resultado |
|---------|------------|------|-----------|
| `pnpm run build` | `ManejApp/` | 0 | Compilación TypeScript OK |
| `npx jest` | `ManejApp/` | 0 | **10** suites, **52** tests pasados. Aviso: `Force exiting Jest` (handles async) |
| `flutter test` | `ManejApp-frontend/` | 0 | **37** tests pasados |
| `flutter analyze` | `ManejApp-frontend/` | 1 | **38** issues (info/warnings; deuda previa del repo) |
| `flutter test integration_test/premium_reservations_e2e_test.dart -d macos --reporter expanded` | `ManejApp-frontend/` | 0 | **7** tests pasados (~4 min 30 s total; primera prueba “Mis reservas” ~3 min) |

**Notas E2E:** puede aparecer `Failed to foreground app; open returned 1` en macOS; la corrida completó. En simulador **iOS/Android**, `127.0.0.1` es el dispositivo: el mock no aplica sin ajustar URL/túnel.

---

## 8. Checklist manual final (demo)

### Alumno

- [ ] Registro → login → home sin errores.
- [ ] Búsqueda / mapa / filtros reales con ubicación.
- [ ] Reserva → pago sandbox Mercado Pago → estado coherente en Mis reservas.
- [ ] Mis pagos alineados con backend.
- [ ] Chat con instructor cuando la política lo permita.
- [ ] Pull-to-refresh en listas críticas.

### Instructor

- [ ] Hub documentos → perfil → dashboard.
- [ ] Crear franja → alumno reserva (flujo real).
- [ ] Mis clases → detalle.

### Sistema

- [ ] Backend caído / timeout: mensajes claros (`ROUTING_QA_CHECKLIST.md`).
- [ ] Deep link desde notificación (si está configurado en el build).

### Dispositivo real (obligatorio para confianza)

- [ ] **Google Sign-In** (SDK + consent).
- [ ] **Face ID / Touch ID** (`local_auth`).
- [ ] **Push** (APNs / FCM; permisos; token registrado en backend).
- [ ] **Mercado Pago** con flujo de pago real o sandbox con tarjeta de prueba.
- [ ] **Crashlytics** (si aplica al build de demo).

---

## 9. Qué depende de dispositivo real o interacción humana

- OAuth Google, biometría, push, MP con UI nativa.
- Exploración “exploratory” de copy, animaciones y red lenta.
- Validación en **iPhone físico** de geolocalización y mapas.

---

## 10. Riesgos pendientes antes de la demo

1. **JWT con rol desactualizado:** tras pasar a instructor, puede hacer falta **re-login** para endpoints que leen rol del token (comportamiento conocido; tests de instructor re-login explícito en backend).
2. **Primera prueba E2E macOS lenta** (~3 min): planificar tiempo de CI o ejecutar por nombre en desarrollo.
3. **`flutter analyze`:** no limpio; riesgo de detalles de estilo, no de lógica verificada por tests.
4. **`ApiService.canContactInstructor`:** usa `GET /payments` y parsea cuerpo como lista; si el backend devuelve solo envelope `{ success, data }`, el cliente puede necesitar ajuste (fuera del alcance de esta QA si no se reproduce en entorno real).
5. **Cobertura admin / notificaciones push:** no sustituida por tests automatizados en este repo.

---

## Referencias de comando

```bash
cd ManejApp && pnpm run build && npx jest

cd ManejApp-frontend && flutter test && flutter analyze
cd ManejApp-frontend && flutter test integration_test/premium_reservations_e2e_test.dart -d macos --reporter expanded
```
