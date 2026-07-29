# Checklist QA premium — ManejApp (pre-release)

Usar con backend en `http://localhost:3000` (o la URL configurada en la app) y simulador iOS/Android según corresponda.

## Auth y sesión

- [ ] Login email/contraseña y Google (si aplica)
- [ ] Sesión persiste al reabrir app; logout limpia token y FCM
- [ ] Tras expiración de sesión, mensaje claro y vuelta a login

## Alumno — núcleo

- [ ] Home: carga, vacío premium, error + reintento
- [ ] Mis reservas: listas, detalle, pago pendiente → MP
- [ ] Buscar instructores / reservar: slots, vacíos, errores
- [ ] Perfil: pull-to-refresh, editar perfil, errores humanizados
- [ ] Ajustes: preferencias de notificaciones
- [ ] Pagos: resumen, tabs, vacío con CTA, error + retry, pago fallido → ir a reserva

## Instructor

- [ ] Dashboard: carga y error premium
- [ ] Agenda y clases: estados async coherentes
- [ ] Onboarding hub: skeleton, error + retry, refresh
- [ ] Documentación: refresh, subida, errores humanizados
- [ ] Completar perfil en mapa: guardado y errores

## Chat (Tanda 2)

- [ ] Lista Mensajes: skeleton primera carga, error vacío + Reintentar, vacío con CTA explorar
- [ ] Búsqueda: sin resultados → limpiar búsqueda
- [ ] Pull-to-refresh en lista
- [ ] Abrir conversación: carga mensajes skeleton, error + Reintentar + volver
- [ ] Chat vacío: copy de bienvenida + campo enviar
- [ ] Enviar mensaje: semántica enviar, error restaura texto, snackbar humano
- [ ] Lista con mensajes: burbujas DS, hora, doble check leído
- [ ] Pull-to-refresh en hilo con mensajes
- [ ] Sin permiso (sin pago): pantalla bloqueo premium + volver
- [ ] Badge de no leídos: color error DS + semántica (lector de pantalla)

## Pagos / rutas

- [ ] Ruta pago sin argumentos válidos: pantalla “Volver”

## Regresiones visuales

- [ ] Tema oscuro consistente (sin azules legacy en chat)
- [ ] Shimmer en listas no “gris genérico” ajeno al DS

## Accesibilidad (muestra)

- [ ] VoiceOver/TalkBack: botones Enviar, Editar perfil, Reintentar en errores
- [ ] Contraste legible en empty/error y chips de estado

---

**Criterio “casi premium de punta a punta”:** todas las áreas anteriores sin texto técnico brusco, con retry o CTA clara, y sin pantallas muertas ante fallo de red.
