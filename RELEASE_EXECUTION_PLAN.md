# ManejApp — Release Execution Plan

Plan operativo para ejecutar el lanzamiento desde el estado actual hasta publicación pública.
Basado en `ManejApp/RELEASE_MASTER_PLAN.md` (sin repetir teoría, orientado a ejecución).

Fecha: 2026-04-30

---

## 1. Orden real de ejecución

Orden recomendado (secuencial):

1. **Fase 1 — Bloqueadores absolutos (P0)**  
   Núcleo: backend productivo + pagos (cobro/comisión/liquidación/conciliación) + privacidad/account deletion + data safety.  
2. **Fase 2 — Estabilidad operativa (P1 crítico de operación)**  
   Monitoreo, alertas, seguridad de documentos y hardening admin/infra.  
3. **Fase 3 — Publicación en stores (go-live controlado)**  
   Checklist App Store/Play, demo accounts/app access, envíos y aprobación.  
4. **Fase 4 — Post-lanzamiento (estabilización)**  
   Respuesta a incidentes, fixes de alto impacto y consolidación operativa.

Regla de avance: **no iniciar Fase 3 si queda algún P0 abierto**.

---

## 2. Fase 1 — Bloqueadores absolutos

### Tarea F1-1 — Account deletion end-to-end

- **Objetivo:** cumplir requisito de stores y privacidad con borrado/anonimización real.
- **Entregable exacto:**  
  - endpoint backend de eliminación de cuenta (con auth),  
  - flujo en app (confirmación + resultado),  
  - política de retención aplicada/documentada.
- **Criterio de terminado:**  
  - usuario solicita eliminación desde app,  
  - backend procesa según política legal,  
  - usuario queda sin acceso y dato tratado como definido (hard delete o anonimización),  
  - evidencia QA del flujo.
- **Archivos/sistemas probablemente involucrados:**  
  `ManejApp/src/modules/users/*`, `ManejApp/src/modules/auth/*`, `ManejApp/prisma/schema.prisma` (si hiciera falta), `ManejApp-frontend/lib/screens/settings_screen.dart`, servicios de API móvil.
- **Dependencia previa:** decisión legal de retención/eliminación.
- **Riesgo si sale mal:** rechazo en stores + riesgo legal/reputacional.

### Tarea F1-2 — Privacy policy + Data Safety/Privacy labels

- **Objetivo:** cerrar compliance documental obligatorio de publicación.
- **Entregable exacto:**  
  - URL pública final de política de privacidad,  
  - formulario Data Safety (Play) completo,  
  - Privacy labels (Apple) completos, consistentes con SDKs/datos reales.
- **Criterio de terminado:** formularios enviados sin inconsistencias y enlazados desde app/stores.
- **Archivos/sistemas probablemente involucrados:** docs legales, App Store Connect, Play Console, pantallas/links de soporte y términos en app.
- **Dependencia previa:** inventario real de datos recolectados y compartidos.
- **Riesgo si sale mal:** bloqueo/rechazo de publicación.

### Tarea F1-3 — Sign in with Apple (P0 condicional)

- **Objetivo:** eliminar riesgo de rechazo por política de login social en iOS.
- **Entregable exacto:**  
  - **Audit de aplicabilidad** (obligatorio),  
  - decisión documentada (requiere SIWA / no requiere con justificación),  
  - implementación y QA si aplica.
- **Criterio de terminado:** decisión trazable + evidencia de cumplimiento en revisión iOS.
- **Archivos/sistemas probablemente involucrados:**  
  `ManejApp-frontend/ios/*`, auth móvil/backend, configuración App Store Connect.
- **Dependencia previa:** auditoría de política vigente y del flujo actual (Google Sign-In).
- **Riesgo si sale mal:** rechazo App Store.

### Tarea F1-4 — Cierre de pagos productivos (separado por dominio)

- **Objetivo:** operar pagos reales sin brechas financieras.
- **Entregable exacto (4 subbloques):**
  1. **Cobro:** credenciales producción + creación de preferencia + webhook verificado en entorno público.
  2. **Comisión:** porcentaje aplicado correctamente y trazable por transacción.
  3. **Liquidación:** regla operativa definida (timing y estado de fondos para instructor/app).
  4. **Conciliación:** rutina diaria (automática/manual) con reporte de diferencias.
- **Criterio de terminado:** flujo de pago E2E real con evidencia de ledger y conciliación sin discrepancias críticas.
- **Archivos/sistemas probablemente involucrados:**  
  `ManejApp/src/modules/payments/*`, variables de entorno backend, webhooks Mercado Pago, reportes admin.
- **Dependencia previa:** cuenta MP productiva habilitada + definición de negocio financiera.
- **Riesgo si sale mal:** cobros fallidos, disputa de comisiones, pérdida de confianza.

### Tarea F1-5 — Backend productivo mínimo verificable

- **Objetivo:** asegurar operación estable previa a envío a stores.
- **Entregable exacto:**  
  secrets productivos, HTTPS, migraciones/tabla auxiliares, backups y restore test básico.
- **Criterio de terminado:** checklist de backend productivo firmado + smoke tests de salud/API/pagos OK.
- **Archivos/sistemas probablemente involucrados:**  
  `ManejApp/src/config/config.ts`, `ManejApp/src/app.ts`, `ManejApp/prisma/*`, `ManejApp/docs/DEPLOYMENT.md`, infra cloud.
- **Dependencia previa:** entorno productivo definido.
- **Riesgo si sale mal:** caída o corrupción de datos en go-live.

### Tarea F1-6 — Gate de QA release (antes de stores)

- **Objetivo:** evitar publicar con regresiones de core flows.
- **Entregable exacto:** ejecución y evidencia de:
  - `flutter analyze`,
  - `flutter test`,
  - tests backend (`npx jest`),
  - smoke E2E manual/automatizado (login, reserva, pago, chat, perfil).
- **Criterio de terminado:** acta única de QA con fecha, build, owner y resultado.
- **Archivos/sistemas probablemente involucrados:**  
  `ManejApp-frontend/test/*`, `ManejApp-frontend/integration_test/*`, `ManejApp/tests/*`, docs QA.
- **Dependencia previa:** tareas F1-1 a F1-5 cerradas.
- **Riesgo si sale mal:** incidente crítico día 0.

---

## 3. Fase 2 — Estabilidad operativa

### Tarea F2-1 — Observabilidad y alertas accionables

- **Objetivo:** detectar incidentes críticos en minutos, no por reporte de usuario.
- **Entregable exacto:** dashboards + alertas para caída API, errores 5xx, pagos fallidos, webhook fallido, auth anómala.
- **Criterio de terminado:** prueba de disparo de alertas con responsables asignados (on-call).
- **Archivos/sistemas probablemente involucrados:** logging backend, herramienta de monitoreo, canales de alerta.
- **Dependencia previa:** backend productivo activo.
- **Riesgo si sale mal:** incidentes no detectados, MTTR alto.

### Tarea F2-2 — Seguridad de documentos y acceso admin

- **Objetivo:** proteger documentación sensible de instructores y reducir riesgo de acceso indebido.
- **Entregable exacto:**  
  - control de acceso estricto en endpoints/admin,  
  - validación de permisos por rol,  
  - endurecimiento de acceso a archivos/documentos,  
  - trazabilidad en logs de acceso administrativo.
- **Criterio de terminado:** pruebas de autorización (403/401 correctos) + auditoría de accesos críticos.
- **Archivos/sistemas probablemente involucrados:**  
  `ManejApp/src/modules/admin/*`, `ManejApp/src/shared/middlewares/auth.ts`, módulos de upload/documents, panel `manejapp-admin`.
- **Dependencia previa:** política de permisos definida.
- **Riesgo si sale mal:** fuga de datos sensibles / incidente de seguridad.

### Tarea F2-3 — Soporte y operación de incidentes

- **Objetivo:** responder bien durante beta y primeras semanas.
- **Entregable exacto:** canal oficial de soporte, SLA, matriz de escalamiento, plantillas de incidentes.
- **Criterio de terminado:** runbook operativo publicado y equipo alineado.
- **Archivos/sistemas probablemente involucrados:** docs operativas, config de canales, panel soporte.
- **Dependencia previa:** responsables asignados.
- **Riesgo si sale mal:** mala experiencia usuario y escalamiento caótico.

### Tarea F2-4 — CI mínimo para evitar regresiones críticas (sin sobrepriorizar)

- **Objetivo:** asegurar un gate básico de calidad, después de núcleo pagos/backend/compliance.
- **Entregable exacto:** workflow backend alineado a comando real de tests y build verde estable.
- **Criterio de terminado:** pipeline ejecuta tests reales y falla correctamente ante regresión.
- **Archivos/sistemas probablemente involucrados:**  
  `ManejApp/.github/workflows/test.yml`, `ManejApp/package.json`.
- **Dependencia previa:** tests estabilizados.
- **Riesgo si sale mal:** degradación silenciosa entre releases.

---

## 4. Fase 3 — Publicación en stores

### Tarea F3-1 — Cierre de paquetes de publicación

- **Objetivo:** tener entregables válidos de release para ambas stores.
- **Entregable exacto:** AAB Android firmado + build iOS firmado con perfiles/certificados correctos.
- **Criterio de terminado:** builds instalables y aprobables en tracks de prueba.
- **Archivos/sistemas probablemente involucrados:**  
  `ManejApp-frontend/pubspec.yaml`, configuración Android/iOS signing.
- **Dependencia previa:** Fase 1 cerrada.
- **Riesgo si sale mal:** bloqueo técnico en envío.

### Tarea F3-2 — App Store Connect completo (incluye acceso reviewer)

- **Objetivo:** enviar app iOS sin faltantes de revisión.
- **Entregable exacto:** metadata, screenshots, privacy labels, categoría, nota de revisión, **demo account/app access** funcional.
- **Criterio de terminado:** envío aceptado para review sin “missing information”.
- **Archivos/sistemas probablemente involucrados:** App Store Connect, credenciales demo, docs internas.
- **Dependencia previa:** compliance legal y SIWA resuelto.
- **Riesgo si sale mal:** rechazo o demoras múltiples.

### Tarea F3-3 — Play Console completo (incluye acceso reviewer)

- **Objetivo:** enviar app Android con compliance y material completo.
- **Entregable exacto:** ficha final, capturas, Data Safety, clasificación de contenido, testing tracks, **demo account/app access**.
- **Criterio de terminado:** release lista para producción sin advertencias bloqueantes.
- **Archivos/sistemas probablemente involucrados:** Play Console, artefactos AAB, docs internas.
- **Dependencia previa:** Data Safety cerrado.
- **Riesgo si sale mal:** rechazo/revisión extendida.

### Tarea F3-4 — Go-live controlado

- **Objetivo:** publicar con riesgo operativo acotado.
- **Entregable exacto:** ventana de lanzamiento + checklist día 0 + monitoreo reforzado + plan rollback.
- **Criterio de terminado:** publicación activa y métricas core dentro de umbral primeras 24-72h.
- **Archivos/sistemas probablemente involucrados:** runbook, monitoreo, backend prod, stores.
- **Dependencia previa:** F3-1 a F3-3.
- **Riesgo si sale mal:** incidente en lanzamiento sin capacidad de respuesta.

---

## 5. Fase 4 — Post-lanzamiento

### Tarea F4-1 — War room de estabilización (semana 1 y 2)

- **Objetivo:** bajar rápido incidentes de adopción inicial.
- **Entregable exacto:** tablero de incidentes, triage diario, owners y ETA.
- **Criterio de terminado:** cero incidentes críticos abiertos y tendencia de errores a la baja.
- **Archivos/sistemas probablemente involucrados:** monitoreo, issue tracker, soporte.
- **Dependencia previa:** app pública.
- **Riesgo si sale mal:** churn temprano y reviews negativas.

### Tarea F4-2 — Ajustes de alta prioridad por datos reales

- **Objetivo:** priorizar impacto real sobre ruido cosmético.
- **Entregable exacto:** lista top de fixes P1/P2 con impacto en conversión, pagos y estabilidad.
- **Criterio de terminado:** lote 1 de fixes desplegado y medido.
- **Archivos/sistemas probablemente involucrados:** móvil, backend, admin.
- **Dependencia previa:** métricas y feedback inicial.
- **Riesgo si sale mal:** estancamiento de calidad percibida.

### Tarea F4-3 — Cierre operativo y traspaso a cadencia regular

- **Objetivo:** salir de modo lanzamiento a operación normal.
- **Entregable exacto:** calendario de mantenimiento, revisión de SLA y roadmap post-release.
- **Criterio de terminado:** cadencia semanal estable y ownership claro.
- **Archivos/sistemas probablemente involucrados:** documentación operativa y roadmap.
- **Dependencia previa:** estabilización inicial.
- **Riesgo si sale mal:** deuda operativa acumulada.

---

## 6. Sprint inicial recomendado (esta semana)

Orden exacto recomendado (6 tareas):

1. **Auditoría SIWA (P0 condicional) + decisión formal documentada.**
2. **Definir política legal de account deletion/retención y traducirla a flujo técnico.**
3. **Implementar account deletion end-to-end (backend + app) con QA del flujo.**
4. **Inventario real de datos/SDKs y cierre de Data Safety + Privacy labels.**
5. **Cierre de pagos productivos: cobro + comisión + liquidación + conciliación con prueba real.**
6. **Ejecutar gate QA release único (analyze/test/jest/smoke E2E) y emitir acta.**

Notas de priorización:
- No mover CI por encima de pagos/backend/compliance.
- No tomar tareas cosméticas en este sprint.

---

## 7. Tickets sugeridos

### Ticket 1

- **Título:** P0 — Auditoría Sign in with Apple y decisión de cumplimiento  
- **Prioridad:** P0 (condicional)  
- **Descripción:** revisar política Apple vigente respecto al login social actual; decidir si requiere SIWA en ManejApp y registrar decisión técnica/legal.  
- **Definition of Done:** documento de decisión aprobado por producto/legal + plan de implementación si aplica.  
- **Dependencias:** ninguna.

### Ticket 2

- **Título:** P0 — Implementar borrado de cuenta completo (backend + app)  
- **Prioridad:** P0  
- **Descripción:** agregar endpoint seguro de eliminación/anonimización y flujo en app desde configuración con confirmación explícita.  
- **Definition of Done:** flujo funcional E2E probado; usuario queda eliminado/anonimizado según política; evidencia QA adjunta.  
- **Dependencias:** política legal de retención definida.

### Ticket 3

- **Título:** P0 — Cierre compliance stores (Privacy Policy + Data Safety + Privacy Labels)  
- **Prioridad:** P0  
- **Descripción:** completar documentación y formularios de stores alineados a datos reales y SDKs instalados.  
- **Definition of Done:** URL de privacy policy pública + formularios Apple/Google completos y consistentes, listos para revisión.  
- **Dependencias:** inventario de datos y SDKs.

### Ticket 4

- **Título:** P0 — Pagos productivos: cobro/comisión/liquidación/conciliación  
- **Prioridad:** P0  
- **Descripción:** cerrar operación de Mercado Pago en producción con prueba real de punta a punta y proceso de conciliación diaria.  
- **Definition of Done:** transacción real validada; comisión correcta; liquidación definida; reporte de conciliación diario sin diferencias críticas.  
- **Dependencias:** cuenta Mercado Pago productiva y reglas financieras definidas.

### Ticket 5

- **Título:** P1 — Seguridad de documentos y hardening de acceso admin  
- **Prioridad:** P1  
- **Descripción:** reforzar autorización sobre endpoints/admin y acceso a documentos sensibles (instructores), con logging auditable.  
- **Definition of Done:** pruebas de autorización pasan (401/403 esperados), accesos sensibles quedan auditados, sin exposición indebida.  
- **Dependencias:** matriz de permisos definida.

### Ticket 6

- **Título:** P1 — Alertas operativas críticas y runbook de incidentes  
- **Prioridad:** P1  
- **Descripción:** activar alertas accionables para API/pagos/auth y formalizar respuesta operativa con escalamiento.  
- **Definition of Done:** alertas probadas con simulación + runbook publicado + on-call asignado.  
- **Dependencias:** entorno de monitoreo operativo.

### Ticket 7

- **Título:** P1 — Publicación stores con demo accounts/app access  
- **Prioridad:** P1  
- **Descripción:** preparar submissions finales en App Store Connect y Play Console incluyendo cuentas demo y notas para reviewer.  
- **Definition of Done:** ambos paquetes listos para enviar sin faltantes de acceso o compliance.  
- **Dependencias:** cierre completo de P0.

### Ticket 8

- **Título:** P1 — Alineación de workflow backend con tests reales  
- **Prioridad:** P1  
- **Descripción:** ajustar pipeline backend para ejecutar comando de tests real y dejar gate estable.  
- **Definition of Done:** CI verde en rama principal y falla reproducible ante regresión.  
- **Dependencias:** tests backend estables.

---

## Núcleo innegociable del lanzamiento (recordatorio operativo)

Antes de publicar, debe estar cerrado y verificado:

1. **Backend productivo**
2. **Pagos productivos (cobro, comisión, liquidación, conciliación)**
3. **Privacidad + account deletion**
4. **Data Safety / Privacy labels**
5. **Acceso de revisión (demo accounts/app access) para stores**

