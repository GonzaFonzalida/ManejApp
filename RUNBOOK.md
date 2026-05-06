# RUNBOOK — Manual para correr ManejApp Backend

Para alguien no técnico: pasos concretos para instalar, configurar, arrancar y probar el backend.

---

## 1. Instalación

### Qué necesitás tener instalado

- **Node.js** (versión 18 o superior). Para verificar: abrí una terminal y escribí `node -v`. Debe mostrar un número (ej. v20.x).
- **pnpm** (gestor de paquetes). Si no lo tenés: `npm install -g pnpm`. Verificar con `pnpm -v`.
- **PostgreSQL** (base de datos). Debe estar instalado y en ejecución. Podés usar una instancia local o un servicio en la nube.

### Pasos

1. Abrí una terminal y entrá a la carpeta del proyecto (donde está `package.json`).
2. Ejecutá:
   ```bash
   pnpm install
   ```
   Esto descarga todas las dependencias del proyecto.

---

## 2. Configuración

### Crear archivo de variables de entorno

1. En la raíz del proyecto debe existir un archivo llamado `.env.example`. Copialo y renombrá la copia a `.env`.
   - En Windows (PowerShell): `Copy-Item .env.example .env`
   - En Mac/Linux: `cp .env.example .env`
2. Abrí `.env` con un editor de texto y completá los valores. **Importante:** el código espera estos nombres (no los del ejemplo si son distintos):
   - `DATABASE_URL` — Cadena de conexión a PostgreSQL. Ejemplo: `postgresql://usuario:contraseña@localhost:5432/manejapp`
   - `JWT_SECRET` — Una frase o clave larga y secreta (mínimo 10 caracteres).
   - `JWT_REFRESH_SECRET` — Otra clave larga y secreta.
   - `JWT_EXPIRATION` — Ej: `15m`
   - `JWT_REFRESH_EXPIRATION` — Ej: `7d`
   - `COOKIE_SECRET` — Otra clave larga y secreta (el código la exige).
   - `MERCADOPAGO_ACCESS_TOKEN` y `MERCADOPAGO_PUBLIC_KEY` — Si vas a probar pagos, poné las claves de Mercado Pago.
   - `PORT` — Ej: `3000` (puerto donde escucha el servidor).

Si dejás nombres como `JWT_EXPIRES_IN` (como en `.env.example`) y el código espera `JWT_EXPIRATION`, la app puede fallar al iniciar. Usá los nombres que aparecen en `src/config/config.ts`.

### Base de datos

1. Creá una base de datos en PostgreSQL para ManejApp (ej. nombre `manejapp`).
2. En `.env`, `DATABASE_URL` debe apuntar a esa base (usuario, contraseña, host, puerto, nombre de la base).
3. Generar el cliente de Prisma y aplicar el modelo a la base:
   ```bash
   npx prisma generate
   npx prisma db push
   ```
   O, si usás migraciones versionadas:
   ```bash
   npx prisma generate
   npx prisma migrate deploy
   ```
4. Si el proyecto usa tabla de logs en la base de datos, puede ser necesario ejecutar el script de setup de logging (ver documentación o `scripts/setup-logging.js`).

---

## 3. Arranque

### Modo desarrollo (recomendado para probar)

```bash
pnpm run dev
```

El servidor se reinicia solo cuando cambiás código. Deberías ver un mensaje tipo “Server corriendo en el puerto 3000”.

### Modo producción

```bash
pnpm run build
pnpm start
```

El primer comando compila el proyecto; el segundo inicia el servidor.

---

## 4. Cómo probarlo

### Health check (navegador o curl)

- **URL:** `http://localhost:3000/health`
- **Qué hace:** Dice si el servidor y la base de datos están bien.
- **Ejemplo con curl:**
  ```bash
  curl http://localhost:3000/health
  ```
  Respuesta esperada: JSON con `"status": "healthy"` y `"services": { "database": "connected", "api": "running" }`.

### Documentación de la API (navegador)

- **URL:** `http://localhost:3000/api-docs`
- Abrís esa URL en el navegador y ves la interfaz de Swagger para explorar los endpoints.

### Login (ejemplo con curl)

- **URL:** `POST http://localhost:3000/api/v1/auth/login`
- **Body (JSON):** email y password de un usuario existente.

Ejemplo:

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"tu@email.com","password":"tucontraseña"}'
```

Si todo está bien, la respuesta incluye un `token` (y posiblemente datos del usuario). Ese token se usa en otras peticiones en el header:

```bash
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer TU_TOKEN_AQUI"
```

### Registrar un usuario (ejemplo)

```bash
curl -X POST http://localhost:3000/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Juan",
    "surname":"Pérez",
    "email":"juan@ejemplo.com",
    "password":"minimo6caracteres",
    "dni":"12345678",
    "birthDate":"2000-01-15"
  }'
```

(Ajustá los campos según lo que pida el backend; puede haber validaciones adicionales.)

### Postman

1. Creá una petición GET a `http://localhost:3000/health` y ejecutala.
2. Para login: método POST, URL `http://localhost:3000/api/v1/auth/login`, en Body elegí “raw” y “JSON”, y poné `{"email":"...","password":"..."}`.
3. Para rutas protegidas: en la pestaña “Authorization” elegí “Bearer Token” y pegá el token que te devolvió el login.

---

## 5. Logs y errores comunes

### Dónde ver los logs

- **Consola:** Si corrés `pnpm run dev`, los mensajes salen en la misma terminal.
- **Archivo:** Si está configurado el logging a archivo, los logs suelen estar en la carpeta `logs/` (ej. `logs/app.log`). Ver variable `LOG_DIRECTORY` en `.env`.
- **Comando para seguir el log en tiempo real (Mac/Linux):**
  ```bash
  pnpm run logs:tail
  ```
  (o `tail -f logs/app.log` si el archivo tiene ese nombre).

### Errores comunes y qué pueden significar

| Mensaje / situación | Posible causa | Qué revisar |
|---------------------|----------------|-------------|
| “JWT_SECRET debe tener al menos 10 caracteres” o fallo al validar env | Variables de entorno faltantes o con nombres incorrectos | Revisar `.env` y que los nombres coincidan con `src/config/config.ts` (ej. `JWT_EXPIRATION`, `COOKIE_SECRET`). |
| “Database connection failed” o error de Prisma al iniciar | No se puede conectar a PostgreSQL | Revisar que PostgreSQL esté corriendo, que `DATABASE_URL` sea correcta (usuario, contraseña, host, puerto, nombre de base). |
| “Port 3000 already in use” | Otro programa está usando el puerto 3000 | Cambiá `PORT` en `.env` (ej. 3001) o cerrá el otro programa que usa el 3000. |
| 404 en una ruta | Ruta incorrecta o no montada | Las rutas de la API empiezan con `/api/v1/`. Revisar `API_MAP.md` o Swagger (`/api-docs`). |
| 401 Unauthorized | Token inválido o no enviado | Para rutas protegidas, enviar header `Authorization: Bearer <token>`. Verificar que el token sea el devuelto por login/refresh. |
| 500 Internal Server Error | Error no manejado en el servidor | Revisar los logs (consola o archivo) para ver el mensaje y el stack trace; suele indicar un bug en código o un dato inesperado. |

---

*Documento generado a partir del análisis del codebase (branch backend-MG-01).*
