# Credenciales de administrador (panel manejapp-admin)

El login del admin usa el **mismo auth del backend** (`/api/v1/auth/login`). El usuario debe tener rol **ADMIN** en la base.

## Demo local (recomendado)

**Email:** `admin@manejapp.app`
**Contraseña:** definida por el script del backend (ver abajo).

Desde la carpeta **`ManejApp/`** del repo:

```bash
node scripts/reset-admin-password.js
```

Ese script **crea** el usuario si no existe o **resetea** la contraseña a la de demo configurada en el propio script. Asegurate de tener `DATABASE_URL` en `.env` y el backend accesible si probás el login justo después.

## Documentación histórica

Las secciones siguientes describían un flujo genérico con `admin@gmail.com`; el proyecto usa **`admin@manejapp.app`** y el script anterior para entornos de demo.
