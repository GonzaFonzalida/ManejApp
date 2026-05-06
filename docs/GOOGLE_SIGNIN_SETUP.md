# Configuración de Login con Google

## Estado actual

El **Client ID** ya está configurado en `.env`. El **Client Secret** no se usa en este flujo (solo verificamos el ID token con el Client ID).

## Importante: configurar orígenes en Google Cloud

Para que funcione en desarrollo, en Google Cloud Console → tu cliente OAuth → **Orígenes JavaScript autorizados**, agregá:

- `http://localhost`
- `http://localhost:7357` ← **obligatorio** (puerto que usa Flutter web en este proyecto)
- `http://localhost:3000`
- `http://127.0.0.1:7357`

Para producción, agregá la URL de tu app (ej. `https://tuapp.com`).

**Ejecutar Flutter web con puerto fijo:**
```bash
cd ManejApp-frontend && flutter run -d chrome --web-hostname=localhost --web-port=7357
```

## Restricción de usuarios de prueba

Si el acceso OAuth está en modo "prueba", solo los usuarios que agregues como **usuarios de prueba** en la pantalla de consentimiento de OAuth podrán iniciar sesión. Para uso público, tendrás que publicar la app (y posiblemente pasar la verificación de Google).

---

## Referencia: crear credenciales desde cero

1. Entrá a [Google Cloud Console](https://console.cloud.google.com/)
2. Creá un proyecto o seleccioná uno existente
3. Andá a **APIs y servicios** → **Credenciales**
4. Clic en **Crear credenciales** → **ID de cliente de OAuth**
5. Tipo de aplicación: **Aplicación web**
6. Orígenes JavaScript autorizados: ver lista arriba

Para **Android** o **iOS**, creá credenciales adicionales del tipo correspondiente y agregá los hashes/certificados según la documentación de Google.

## 2. Configurar el backend

En el archivo `.env` del backend, agregá:

```
GOOGLE_CLIENT_ID="tu-id-de-cliente.apps.googleusercontent.com"
```

Reiniciá el backend para que tome la variable.

## 3. Verificar

1. El endpoint `GET /api/v1/config` devuelve `googleClientId` cuando está configurado
2. El frontend carga esa config al iniciar y muestra el botón solo si existe
3. Al tocar "Continuar con Google", se abre el popup de Google, el usuario elige su cuenta, y la app recibe el token para autenticarse

## Flujo técnico

- **Frontend**: usa `google_sign_in` para obtener un ID token de Google
- **Frontend**: envía ese token a `POST /api/v1/auth/google`
- **Backend**: verifica el token con la librería `google-auth-library`
- **Backend**: busca o crea el usuario, devuelve JWT de la app
- **Frontend**: guarda el JWT y redirige al dashboard

## Usuarios nuevos vs existentes

- Si el usuario no existe: se crea automáticamente con email verificado, rol STUDENT
- Si ya existe una cuenta con ese email: se vincula la cuenta de Google (puede usar ambos métodos para entrar)
