# Política de Privacidad — ManejApp (plantilla operativa)

**Versión:** texto para revisión legal antes de publicar (web y/o app).  
**Base técnica:** inventario del repositorio y **manifest fusionado Android release** (`DATA_AND_SDK_INVENTORY.md`).  
**Limitación:** este documento **no** sustituye asesoramiento jurídico ni garantiza que las declaraciones cumplan normativa aplicable en cada mercado.

**Contacto de privacidad (completar antes de publicar):**  
**[COMPLETAR: correo de privacidad / titular del tratamiento / domicilio legal]**

---

## 1. Quién somos

**[COMPLETAR: razón social y titular del tratamiento]** opera la plataforma **ManejApp**, que conecta personas que desean tomar clases de manejo con instructores, incluyendo funciones de reserva, mensajería y pagos según la versión desplegada.

Esta política describe cómo tratamos los datos personales en la **aplicación móvil**, el **servidor (API)** y el **panel de administración** asociado.

---

## 2. Qué datos recopilamos

### 2.1 Datos que nos proporcionás al registrarte o usar la cuenta

- **Identidad y cuenta:** nombre, apellido, correo electrónico, documento nacional de identidad (DNI u equivalente), fecha de nacimiento, contraseña (almacenada de forma segura en el servidor), rol (alumno, instructor o administrador según corresponda).
- **Verificación de correo:** datos necesarios para enviarte un enlace o flujo de verificación.
- **Inicio de sesión con Google:** cuando lo habilitamos, podemos recibir identificador de cuenta Google y datos básicos de perfil que Google pone a disposición del servicio (según tu configuración de Google).
- **Inicio de sesión con Apple (solo iOS):** cuando lo usás, Apple puede proporcionar un **token de identidad** que el servidor valida; podemos persistir un **identificador estable de cuenta Apple** (`appleSub`), **correo** (incluido relay `@privaterelay.appleid.com` si elegís ocultar email) y **nombre/apellido** cuando Apple los envía (típicamente en el primer inicio).

### 2.2 Datos de contacto y perfil

- **Teléfono** (si lo cargás; puede ser opcional según el formulario).
- **Dirección o ubicación en texto** (por ejemplo para instructores o búsqueda en mapa).
- **Foto de perfil** (si la subís).

### 2.3 Ubicación

- Si la app solicita permiso de **ubicación**, puede usarse para mostrar instructores en mapa o mejorar la experiencia de búsqueda según la pantalla. Los permisos concretos figuran en la configuración del sistema operativo (iOS/Android).

### 2.4 Documentación de instructores

Si sos instructor, podemos recolectar **imágenes o archivos** exigidos por el servicio (por ejemplo documentación vehicular o habilitante), almacenados en servidores controlados por el operador del backend, y datos asociados a **revisión administrativa** (estados de aprobación).

### 2.5 Reservas, clases y datos de negocio

- Datos sobre **reservas/clases** (fechas, duración, estado, montos asociados cuando aplique, notas operativas).
- Datos sobre **vehículos** del instructor cuando se cargan en la plataforma.

### 2.6 Pagos

Los pagos pueden procesarse a través de **Mercado Pago**. El operador de ManejApp y/o Mercado Pago pueden tratar datos necesarios para iniciar el cobro, confirmarlo y cumplir obligaciones contables (por ejemplo montos, identificadores de transacción, estado).  
**No sustituimos la política de privacidad de Mercado Pago:** te recomendamos leerla al pagar.

### 2.7 Mensajes

Si usás el chat interno, almacenamos los **mensajes** entre usuarios participantes y metadatos (fechas, estado de lectura cuando aplique).

### 2.8 Notificaciones

- **Preferencias** de notificaciones por correo y/o push (según implementación activa).
- **Token de dispositivo** para notificaciones push cuando corresponda (**Firebase Cloud Messaging** en backend vía Firebase Admin; en **Android** el **SDK FCM está incluido en el binario release** según manifest fusionado).

> **Nota técnica:** el servidor puede almacenar tokens FCM (`NotificationToken`). En el cliente Flutter, el servicio Dart de notificaciones puede estar **incompleto** respecto del envío del token al backend; eso **no** implica ausencia del SDK en Android. En **iOS**, el `Podfile.lock` actual **no** muestra pods Firebase cliente — revisar cada versión publicada en tiendas.

### 2.9 Datos técnicos, analytics y de seguridad

- **Sesiones y tokens** de autenticación.
- **Dirección IP y agente de usuario** pueden registrarse en sesiones del servidor para seguridad y diagnóstico.
- **Registros (logs)** del servidor según configuración operativa.
- **Android (build release validado):** la app incluye componentes de **Google Analytics for Firebase / Measurement** (servicios listados en el manifest fusionado). Eso puede implicar datos de **uso de la app** y **identificadores** tratados por Google según sus políticas; **legal** debe alinear el texto con lo declarado en **Google Play Data Safety**.
- **Identificador de publicidad (Android):** el manifest fusionado incluye permisos relacionados con **AD_ID** / servicios de anuncios coherentes con la cadena de dependencias de Measurement — revisar con legal cómo describirlo frente al usuario y en tiendas.

### 2.10 Panel administrativo

Los usuarios con rol administrativo acceden a datos necesarios para **moderación, soporte operativo y cumplimiento** (por ejemplo revisión de instructores y reportes).

---

## 3. Finalidades del tratamiento

Usamos los datos para:

1. Crear y mantener tu cuenta y rol en la plataforma.  
2. Verificar identidad de correo y recuperar acceso.  
3. Facilitar la contratación/reserva de clases y la comunicación entre partes.  
4. Procesar pagos y comisiones cuando corresponda.  
5. Enviar notificaciones que solicitaste o que son necesarias para el servicio (recordatorios, cambios de estado).  
6. Cumplir obligaciones legales y resolver disputas.  
7. Mejorar seguridad, prevenir fraude y mantener la integridad del servicio.  
8. **Android:** analizar uso de la app mediante **Firebase Analytics / Measurement** (presente en el binario release analizado). **iOS:** según dependencias actuales del proyecto, **no** se observó la misma pila Firebase en cliente — si cambia el binario, actualizar política y formularios de tienda.

---

## 4. Base legal (marcador para legal)

**[COMPLETAR según jurisdicción: consentimiento, ejecución de contrato, interés legítimo, obligación legal, etc.]**

---

## 5. Conservación de datos

- Conservamos los datos **el tiempo necesario** para prestar el servicio y cumplir obligaciones legales y contables.
- Los registros de **pagos y reservas** pueden conservarse aun después del cierre de cuenta en la medida en que el derecho aplicable lo exija.
- Política técnica de **baja de cuenta** (anonimización y bloqueo): ver documento interno **`ACCOUNT_DELETION_POLICY.md`** y la sección 9 de esta política.

---

## 6. Tus derechos

Según la ley aplicable, podés tener derecho a:

- Acceder, rectificar o actualizar tus datos.  
- Oponerte o limitar ciertos tratamientos.  
- Solicitar portabilidad cuando corresponda.  
- Retirar consentimiento cuando el tratamiento se base en él.

**[COMPLETAR procedimiento y plazos según jurisdicción]**

---

## 7. Compartición con terceros

Podemos compartir datos con proveedores que actúan siguiendo nuestras instrucciones:

| Categoría | Ejemplos en el proyecto |
|-----------|-------------------------|
| Pagos | Mercado Pago |
| Autenticación social | Google (Sign-In); **Apple (Sign in with Apple, solo app iOS)** |
| Mapas | Google Maps Platform |
| Mensajería push | Google (FCM en servidor vía Firebase Admin; SDK FCM en **Android release**) |
| Analytics / uso de app (Android) | Google (Firebase Analytics / Measurement en binario release) |
| Correo transaccional | Servicio SMTP configurado (p. ej. Gmail en configuración de ejemplo del repo) |

**[LEGAL:]** incorporar encargados del tratamiento (subprocessors), transferencias internacionales y garantías.

---

## 8. Seguridad

Aplicamos medidas razonables de seguridad técnica y organizativa (autenticación, HTTPS en producción esperado, hashing de contraseñas en servidor, controles de rol). Ningún sistema es 100% seguro.

---

## 9. Eliminación de cuenta (App Store / Play Store)

Podés solicitar la eliminación de tu cuenta desde la **configuración de la app** (flujo implementado en la versión actual del proyecto), lo cual desencadena:

- invalidación de sesiones y tokens de notificación asociados al usuario en el servidor;  
- anonimización de datos personales principales y bloqueo de acceso;  
- tratamiento de mensajes y datos relacionados según la política técnica documentada en **`ACCOUNT_DELETION_POLICY.md`**.

Algunos datos pueden **conservarse de forma anonimizada o agregada** para cumplir obligaciones legales o mantener registros de negocio (por ejemplo historial de transacciones sin datos identificativos cuando sea posible).

---

## 10. Menores

**[COMPLETAR]** edad mínima y consentimiento parental según mercado.

---

## 11. Cambios

Podemos actualizar esta política. Publicaremos la versión vigente en **[COMPLETAR URL]** y, si el cambio es material, te informaremos por los medios adecuados.

---

## 12. Contacto

Privacidad: **[COMPLETAR]**  
Soporte general (si aplica): el correo usado en comunicaciones de la app debe ser revisado para que coincida con el canal oficial — en plantillas de ejemplo del código aparece `soporte@manejapp.com`; debe validarse antes de publicar.

---

### Anexo: referencia técnica

No forma parte del texto legal para usuarios finales, pero útil para equipos internos:

- `DATA_AND_SDK_INVENTORY.md` — inventario detallado.  
- `STORE_PRIVACY_MAPPING.md` — mapeo a formularios de tiendas.  
- `SIWA_CLOSURE_CHECKLIST.md` — cierre operativo Sign in with Apple (QA / Developer / App Privacy).
- `ACCOUNT_DELETION_POLICY.md` — borrado/anonymization técnico.
