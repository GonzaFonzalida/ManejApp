# Sign in with Apple — checklist de cierre operativo

**Propósito:** marcar SIWA como **done** en release/compliance, no solo como código que compila.  
**Implementación en repo:** ver `SIWA_AUDIT.md` §9 (actualización post-código).

Marcá cada ítem cuando lo hayas completado y podás evidenciarlo (captura, nota de QA, o enlace interno).

---

## Apple Developer (portal)

- [ ] **Identifiers → App IDs:** el App ID coincide con el Bundle ID del binario que subís (p. ej. `com.gonzalofonzalida.manejapp`).
- [ ] **Sign In with Apple** está **habilitado** en ese App ID (capability).
- [ ] **Provisioning profiles** (Development / Distribution) regenerados o actualizados después del cambio, si Xcode/App Store Connect lo requirieron.
- [ ] El equipo que firma en Xcode usa un perfil que incluye esa capability.

---

## Xcode

- [ ] Target **Runner → Signing & Capabilities:** aparece **Sign In with Apple** (coherente con `ios/Runner/Runner.entitlements`).
- [ ] Build **Archive** para distribución sin errores de entitlements.
- [ ] **Team** y **Bundle Identifier** coinciden con el App ID anterior.

---

## Backend / operaciones

- [ ] En `.env` de **cada entorno** (staging/prod): **`APPLE_CLIENT_ID`** = **exactamente el mismo string que el Bundle ID de la app iOS** que firma el `identityToken` (en este proyecto: típicamente `com.gonzalofonzalida.manejapp`). Si en producción el bundle es otro, el valor debe cambiar en consecuencia.
- [ ] API desplegada alcanzable desde el iPhone de prueba (`NEXT_PUBLIC_API_URL` / configuración Flutter).
- [ ] Migración Prisma aplicada donde corre la DB (`apple_sub`).

---

## Prueba real en iPhone (smoke E2E)

- [ ] Login Apple **usuario nuevo** (creación cuenta backend): correo real o relay `@privaterelay.appleid.com`; nombre en primer login si Apple lo envía.
- [ ] **Segundo login** mismo Apple ID: sesión correcta sin depender de reintroducir nombre.
- [ ] **Logout** y login Apple de nuevo.
- [ ] Sin regresión: login **email/contraseña** y **Google** siguen funcionando.
- [ ] **Registro** pantalla: botón Apple solo iOS, comportamiento aceptable.

---

## Account deletion con Apple

- [ ] Usuario creado vía Apple (o cuenta enlazada con `appleSub`): **Eliminar cuenta** desde Ajustes **sin pedir contraseña** (flujo OAuth).
- [ ] Tras borrar: no se puede volver a usar la **misma sesión**; intento de `/auth/me` con token viejo rechazado.
- [ ] Opcional DB: `apple_sub` del usuario anonimizado queda **null** (coherente con `ACCOUNT_DELETION_POLICY.md`).

---

## Privacy / compliance

- [ ] **Política de privacidad** publicada (URL final) menciona inicio de sesión con Apple y tratamiento coherente con lo que guardás (`appleSub`, email del token). Revisión **legal** hecha o agendada.
- [ ] **App Store Connect → App Privacy:** datos actualizados según `STORE_PRIVACY_MAPPING.md` (Contact Info / Identifiers / Third-party account / Linked third-party según aplique a tu taxonomía y criterio legal).
- [ ] Coherencia entre formulario App Privacy, política pública e inventario (`DATA_AND_SDK_INVENTORY.md`).

---

## Definición de “SIWA cerrado”

Podés marcar el ticket **cerrado en sentido release** cuando **todos** los bloques anteriores estén completados **y** tengas evidencia de la fila “Prueba real en iPhone”.

Hasta entonces: **implementación técnica lista; cierre operativo pendiente** (sin ambigüedad para auditoría interna).
