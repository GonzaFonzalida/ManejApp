# ManejApp — Release Master Plan (Fuente de verdad)

Documento maestro de lanzamiento consolidado desde el estado real del repo (backend `ManejApp/`, app móvil `ManejApp-frontend/`, panel `manejapp-admin/`) y documentación existente.

Fecha de consolidación: 2026-04-30

---

## 1. Estado actual del proyecto

### Resumen breve y honesto

El proyecto tiene una base funcional avanzada (backend modular, app Flutter con múltiples flujos, integración Mercado Pago, panel admin), pero **todavía no está listo para llamarse “terminado y publicable”** sin cerrar bloqueadores de producción, compliance de stores y operación real.

Hay documentos internos que declaran "100% completado", pero el estado verificable en código y checklists muestra pendientes clave para lanzamiento público.

### Qué ya está funcionando (evidencia en código)

- Backend Express + TypeScript con módulos de auth, users, instructors, clases, pagos, schedule, notifications, messages y admin.
- API versionada bajo `/api/v1/*` y endpoint de config público `GET /api/v1/config`.
- Integración Mercado Pago con creación de preferencias y webhook (`/api/v1/payments/mercadopago/webhook`).
- Sistema de comisiones con rutas dedicadas.
- Seguridad base implementada (helmet, CORS, rate limit, validación).
- Logging estructurado (console/file/db configurable) y health check (`/health`).
- Tests backend existentes con Jest (integración y unitarios en `ManejApp/tests`), aunque sin script `test` en `package.json`.
- Flutter con flujo de auth, reservas, pagos, mapas, settings y tests (`test/` + `integration_test/`).
- iOS base configurado para demo (bundle id, permisos, guía de signing manual).

### Qué hoy impide llamarla “terminada”

- **Compliance de stores incompleto**: borrado de cuenta no implementado end-to-end (solo placeholder UI), privacy policy/data safety no cerrados.
- **Publicación stores no cerrada**: metadata/assets/checklists están documentados pero no evidencian ejecución completa real.
- **Operación de producción incompleta**: alertas automáticas críticas (email/incident) no cerradas en código, observabilidad centralizada no operativizada.
- **QA de release no consolidada con evidencia única**: hay varios documentos y planes parciales dispersos.
- **CI/CD incompleto**: workflow de backend existe, pero depende de `npm test` y el script no está definido en backend.
- **Decisiones de negocio/regulatorias pendientes**: flujo final de comisión/liquidación, soporte post-lanzamiento, SLA operativo.

### Estado por área (hecho vs parcial vs faltante)

| Área | Hecho | Parcial | Falta completo |
|---|---|---|---|
| Pagos | Integración MP + webhook + comisiones en backend | Cierre operativo de marketplace/onboarding instructores y conciliación | Cierre de liquidación financiera y proceso contable/auditable formal |
| Backend/Infra | API, seguridad base, health, logging, scheduler | Hardening producción, backups, secretos y runbooks operativos finales | Infra productiva validada con alertas y pruebas de recuperación documentadas |
| Observabilidad | Logs y métricas base en código | Alertas accionables y monitoreo de incidentes | Operación 24/7 con umbrales, on-call y playbooks |
| Stores/Compliance | Guías de publicación y checklist de demo | Preparación de assets/metadata y testing de release | App Store/Play checklist legal/técnico cerrado con evidencia |
| Privacidad/Legal | Referencias en docs y pantallas de términos placeholder | Definición de política de privacidad y data usage | Borrado de cuenta real + proceso legal de derechos ARCO/GDPR equivalente |
| QA/Testing | Tests backend + tests Flutter existentes | Cobertura de regresión release y evidencia única de QA | Gate de release obligatorio con evidencia firmada |
| Release/CI-CD | Workflow backend presente | Pipeline requiere ajustes (script test y criterios) | Pipeline integral multi-proyecto y estrategia de release reproducible |
| Operación/Soporte | Base documental inicial | Definir canales, tiempos, escalamiento | Soporte post-lanzamiento formal (SLA, incidentes, comunicación) |
| UX post-lanzamiento | UX funcional en flows core | Placeholders en soporte/legal y ajustes de detalle | Plan de polish + priorización por feedback real |

---

## 2. Definition of Done real para ManejApp

### 2.1 App “terminada” (producto base)

Se considera terminada cuando:

- Flujos core (registro/login, reserva, pago, mensajería, gestión por roles) están estables con evidencia de QA.
- No hay placeholders en funcionalidades exigidas por negocio/compliance.
- Errores críticos (P0) cerrados y validados.

### 2.2 App “operable” (operación técnica)

- Infra de producción activa con secretos, HTTPS, backups y recuperación probada.
- Monitoreo + alertas críticas (pagos, auth, caída de API, errores) funcionando.
- Runbook operativo y plan de incidentes vigente.

### 2.3 Lista para beta seria

- Build reproducible Android/iOS, testers reales activos, feedback loop y bug triage semanal.
- Métricas mínimas definidas (crash-free rate, éxito de pago, éxito de reservas, latencia API).

### 2.4 Lista para App Store / Play Store

- Requisitos de tienda completos: metadata, assets, política de privacidad pública, data safety/privacy labels.
- Función de borrado de cuenta operativa y verificable.
- Cumplimientos de login social revisados (si aplica Sign in with Apple por políticas vigentes).

### 2.5 Lista para salida al público

- No hay bloqueadores de publicación activos.
- Soporte y monitoreo listos para volumen inicial.
- Plan de lanzamiento día 0 + contingencia + comunicación a usuarios definido.

---

## 3. Lista maestra de pendientes

> Prioridad: **P0 bloquea lanzamiento**, **P1 crítico para operar bien**, **P2 mejora post-release controlada**.

| Prioridad | Área | Tarea | Qué significa terminarla | Dependencias | Estado actual | Responsable sugerido | Riesgo si no se hace |
|---|---|---|---|---|---|---|---|
| P0 | Privacidad / legal | Implementar borrado de cuenta end-to-end | Endpoint backend + UX en app + eliminación/anonimización + confirmación al usuario | Decisión legal de retención de datos | **Parcial** (placeholder en settings) | Backend + Mobile + Legal | Rechazo en stores / riesgo legal |
| P0 | Stores / compliance | Publicar política de privacidad y enlazarla en app/stores | URL pública final + contenido alineado a datos reales recolectados | Legal / negocio | **Parcial** (mencionada en docs, no evidencia final) | Legal + Producto | Bloqueo de aprobación store |
| P0 | Stores / compliance | Completar Data Safety (Play) y Privacy Nutrition (Apple) | Formularios completos y consistentes con SDKs/datos reales | Inventario de datos y SDKs | **Faltante** | Producto + Legal + Mobile | Rechazo en revisión |
| P0 | Stores / auth | Validar requisito Sign in with Apple | Decisión formal: implementar SIWA o justificar no aplicable según políticas vigentes | Estrategia de login social | **Faltante** (hay Google Sign-In iOS) | Mobile + Producto | Rechazo App Store |
| P0 | Pagos | Cerrar flujo productivo Mercado Pago marketplace/liquidación | Credenciales producción + onboarding instructores + webhook verificado + conciliación diaria | Cuenta MP y negocio financiero | **Parcial** | Backend + Ops + Finanzas | Cobros fallidos / disputas de dinero |
| P0 | Backend / infra | Alinear CI backend con tests reales | Definir script `test` o ajustar workflow para `npx jest` y dejar CI verde | Repo backend y workflow actual | **Parcial** | Backend | Sin gate confiable de calidad |
| P0 | QA / testing | Ejecutar release QA con evidencia única | `flutter analyze`, `flutter test`, backend tests, smoke E2E pagos/reservas/login con acta | Entorno staging confiable | **Parcial** | QA + Mobile + Backend | Lanzar con regresiones críticas |
| P1 | Observabilidad | Activar alertas operativas (errores críticos, caída API, pagos) | Alertas reales (email/chat/on-call), umbrales y responsables definidos | Herramienta monitoreo | **Parcial** (logging existe; alertas incompletas) | Backend + DevOps | Incidentes sin detección temprana |
| P1 | Backend / infraestructura | Endurecer producción (secrets, backup, restore test) | Backup automático + restore probado + secretos fuera de repo + checklist firmado | Infra cloud elegida | **Parcial** | DevOps | Pérdida de datos / caída prolongada |
| P1 | Release / CI-CD | Pipeline de release mobile reproducible | Build firmada + versionado + artifacts + checklist automatizable | Keystore/certificados | **Parcial** | Mobile | Releases manuales propensas a error |
| P1 | Operación / soporte | Definir soporte post-lanzamiento | Canal soporte, SLA, escalamiento, plantillas de incidentes | Equipo operativo | **Faltante** | Producto + Soporte | Mala respuesta a usuarios |
| P1 | QA / beta | Beta cerrada con cohorte real y métricas | 20-100 testers, seguimiento bugs, criterios de salida beta | Builds internas estables | **Parcial** | QA + Producto | Publicar sin validación real de campo |
| P1 | Privacidad / legal | Términos y condiciones reales en app | Pantalla funcional + documento legal vigente enlazado | Legal | **Parcial** (tile placeholder) | Mobile + Legal | Riesgo legal/contractual |
| P2 | UX polish post-lanzamiento | Resolver placeholders de “Centro de ayuda” y flujos secundarios | Pantallas funcionales y consistentes | Definición de contenido | **Parcial** | Mobile + Producto | Deuda UX y soporte confuso |
| P2 | Observabilidad | Integrar crash reporting móvil de forma operativa | Crashlytics/SDK equivalente activo, dashboard y alertas | Firebase prod | **Parcial** (mencionado en docs) | Mobile | Menor visibilidad de fallas cliente |
| P2 | Backend | Unificar documentación dispersa y obsoleta | Marcar docs históricas como archivadas y mantener este plan | Aprobación equipo | **Parcial** | Tech Lead | Decisiones basadas en docs viejas |

---

## 4. Plan por fases

## Fase 1 — Bloqueadores de lanzamiento (P0)

**Objetivos**

- Eliminar riesgos de rechazo en stores y fallas críticas de pago/release.

**Tareas**

- Borrado de cuenta real.
- Privacy policy + data safety + validación SIWA.
- Cierre operativo de Mercado Pago producción.
- CI backend verde con estrategia de tests definida.
- QA release mínimo obligatorio con evidencia.

**Criterio de salida**

- Todos los P0 en estado “completado y verificado”.

**Riesgos**

- Rechazo stores, bloqueos legales, cobros inestables.

## Fase 2 — Beta cerrada seria (P1 QA + Ops)

**Objetivos**

- Validar estabilidad con usuarios reales controlados.

**Tareas**

- Cohorte beta cerrada.
- Monitoreo/alertas operativas activas.
- Runbook de soporte e incidentes.

**Criterio de salida**

- Métricas beta dentro de umbral y sin incidentes severos abiertos.

**Riesgos**

- Sesgo de test insuficiente, incidentes no detectados.

## Fase 3 — Publicación (stores + go-live)

**Objetivos**

- Publicar Android/iOS con operación preparada.

**Tareas**

- Subida final de builds firmadas.
- Metadata, screenshots, clasificaciones y formularios store completos.
- Go-live backend con monitoreo reforzado.

**Criterio de salida**

- Apps aprobadas y release habilitada al público.

**Riesgos**

- Rechazos de último minuto, errores de configuración en producción.

## Fase 4 — Post-lanzamiento (estabilización)

**Objetivos**

- Estabilizar operación y convertir feedback en mejoras priorizadas.

**Tareas**

- Triage de bugs de producción.
- Ajustes UX de soporte/legales.
- Mejora de observabilidad y performance.

**Criterio de salida**

- Incidentes críticos controlados y backlog P1 reducido.

**Riesgos**

- Deuda operativa y mala retención temprana.

---

## 5. Bloqueadores reales de publicación

### Esto bloquea subir/publicar

1. **Borrado de cuenta no implementado end-to-end** (solo placeholder en UI).
2. **Privacy policy + Data Safety/Privacy labels no cerrados con evidencia final**.
3. **Requisito Sign in with Apple no resuelto** (hay Google Sign-In iOS).
4. **Flujo de pagos en producción no cerrado operativamente** (marketplace/liquidación/conciliación).
5. **CI de backend no alineado con ejecución real de tests**.
6. **QA de release sin evidencia consolidada única y reproducible**.

---

## 6. Checklist operativo de lanzamiento

## Backend

- [ ] Variables de entorno de producción validadas (`DATABASE_URL`, JWT, cookies, MP, logging).
- [ ] Migraciones y tablas auxiliares aplicadas.
- [ ] Webhook Mercado Pago accesible externamente y verificado.
- [ ] Health check y endpoints críticos smoke-tested.
- [ ] Backup + restore test documentado.

## Mobile

- [ ] `flutter analyze` sin errores nuevos.
- [ ] `flutter test` pasando en suite afectada + core suite.
- [ ] Build Android AAB firmada.
- [ ] Build iOS lista (signing/certificados/perfiles).
- [ ] Configuración Firebase producción confirmada.

## App Store Connect

- [ ] Metadata, screenshots, keywords, categorías finales.
- [ ] Privacy policy URL válida.
- [ ] Privacy Nutrition Labels completadas.
- [ ] Validación de Sign in with Apple resuelta.
- [ ] Demo account/documentación para review si aplica.

## Play Console

- [ ] Ficha completa (texto + assets).
- [ ] Data Safety completado y consistente.
- [ ] Clasificación de contenido cerrada.
- [ ] Testing tracks (interno/cerrado) validados.

## QA final

- [ ] Smoke E2E: registro/login, reserva, pago, chat, perfil.
- [ ] Escenarios de error: pago fallido, sesión expirada, red inestable.
- [ ] Validación de roles (student/instructor/admin).
- [ ] Evidencia centralizada (fecha, build, resultado, owner).

## Monitoreo

- [ ] Dashboards de API, pagos, errores y latencia activos.
- [ ] Alertas críticas probadas (no solo configuradas).
- [ ] Logs de producción accesibles por el equipo on-call.

## Soporte

- [ ] Canal de soporte visible en app y stores.
- [ ] Plantillas de respuesta para incidentes frecuentes.
- [ ] Responsable on-call y escalamiento definidos para semana 1.

---

## 7. Próximos pasos inmediatos — Qué arrancamos ya

1. Implementar **borrado de cuenta real** (backend + app + política de retención).
2. Cerrar **privacy policy + Data Safety/Privacy labels** con inventario de datos real.
3. Resolver decisión y ejecución de **Sign in with Apple (si aplica)**.
4. Ejecutar **hardening de pagos productivos** (credenciales, webhook, conciliación y prueba real).
5. Corregir **pipeline backend** (script de test/workflow) y dejar CI verde estable.
6. Definir y correr **QA release gate** con evidencia única reproducible.
7. Configurar **alertas operativas críticas** (pagos, auth, caída API, errores severos).
8. Cerrar **runbook de incidentes + soporte** (SLA, escalamiento, responsables).
9. Preparar y validar **assets/metadata finales de stores** (no demo).
10. Ejecutar una **beta cerrada controlada** antes del envío a producción pública.

---

## Notas de decisión pendientes (negocio/legales)

- Política exacta de retención/eliminación de datos al borrar cuenta.
- Modelo operativo de comisión/liquidación (tiempos, disputas, conciliación).
- Nivel de soporte comprometido (horario, SLA, canales).
- Alcance inicial de lanzamiento (geografía, volumen esperado, cohortes).

Si estas decisiones no se cierran, el lanzamiento queda técnicamente posible pero operativamente riesgoso.

