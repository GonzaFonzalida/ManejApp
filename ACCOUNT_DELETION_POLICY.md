# Política técnica de baja de cuenta (anonimización)

**Alcance:** documentación técnica para implementación y QA. No sustituye asesoría legal; revisión legal pendiente.

## Resumen

La aplicación **no elimina en duro** la fila `User` cuando existen referencias de negocio (p. ej. `DrivingClass`, pagos) que impedirían integridad referencial. En su lugar se aplica **anonimización de PII**, revocación de sesiones y tokens push, y bloqueo de acceso (`isActive: false`, `accountDeletedAt`).

## Borrar / anonimizar / retener

| Entidad / dato | Acción |
|----------------|--------|
| `Session` | Eliminar filas (`deleteMany` por `userId`) |
| `NotificationToken` | Eliminar |
| `Message` (enviados por el usuario) | Contenido sustituido por texto neutro |
| `User` (PII) | Anonimizar: nombre/apellido genéricos, email y DNI únicos placeholder, contraseña aleatoria, `googleId` null, teléfono/ubicación/imagen perfil nulos, tokens de email/reset anulados |
| `User.accountDeletedAt` | Establecer fecha de baja |
| `User.isActive` | `false` |
| `Instructor` (si aplica) | Anular `mpAccessToken`, rutas de documentos y campos libres sensibles (bio, fotos, dirección); mantener fila por FKs |
| `DrivingClass`, `Payment`, `Student`, `Instructor` (filas) | **Retener** IDs y datos mínimos de negocio |
| Archivos en disco (perfil, documentos instructor) | Eliminar en lo posible tras confirmar transacción DB |
| Apple Sign In (`appleSub`) | **Anulado** (`null`) en el mismo bloque que `googleId` (`user.services.ts`) |

## Limitación conocida (access token JWT)

El access token JWT puede seguir siendo criptográficamente válido hasta su expiración. Se mitiga consultando en el middleware `authenticate` del módulo auth si la cuenta está eliminada o inactiva.

## Endpoint

- `POST /api/v1/users/me/delete-account`
- Cuerpo: `confirmPhrase` debe ser exactamente `ELIMINAR`; `password` obligatoria si el usuario **no** tiene cuenta Google **ni** Apple vinculada (`googleId` / `appleSub`).
- Perfil **ADMIN**: respuesta `403` desde la app de usuario.

## Verificación (QA)

Checklist manual:

1. Usuario alumno/instructor con contraseña: eliminar con frase + contraseña → sesión cerrada, login posterior falla.
2. Usuario con Google: eliminar solo con frase → mismo comportamiento.
3. Usuario con Apple (SIWA): eliminar solo con frase → mismo comportamiento; `appleSub` anulado en BD.
4. Tras eliminar, una petición autenticada con el access token anterior debe responder `401`.
5. Mensajes enviados por el usuario muestran texto anonimizado.

Comandos (desde carpetas del repo):

- Backend `ManejApp/`: `pnpm run build`, `pnpm exec jest`
- Flutter `ManejApp-frontend/`: `flutter analyze`, `flutter test`

Registrar fecha y resultado de cada comando en el PR o ticket de release.
