# QA — Verificación de endpoints (RoleRouter / ApiService)

Evidencia de que los endpoints consumidos por el Flutter `RoleRouter` y `ApiService` responden como se espera.

## Cómo ejecutar

1. Backend en marcha: `npm run dev` (o `node dist/app.js`).
2. Opcional: usuario QA en DB con email/contraseña conocidos (o usar los de `cargasParaTest.txt`).
3. Ejecutar:
   ```bash
   QA_EMAIL=fig@gmail.com QA_PASSWORD=02320648767Si. BASE_URL=http://localhost:3000 node scripts/qa-verify-endpoints.js
   ```
4. Copiar la salida y pegarla en "Evidencia capturada" más abajo.

## Endpoints verificados

| Endpoint | Esperado | Uso en Flutter |
|----------|----------|----------------|
| `POST /api/v1/auth/login` | 200, `accessToken` + `user.id` (o decodificable desde JWT) | Login; obtener token y userId |
| `GET /api/v1/auth/me` | 200 con Bearer | Validar token en `RoleRouter` |
| `GET /api/v1/users/:id` | 200, cuerpo con `role` | Rol real desde DB (evitar JWT stale) |
| `GET /api/v1/instructors/me` | 200 si INSTRUCTOR, 403 si STUDENT (no 500) | Completar perfil / dashboard instructor |
| `PUT /api/v1/instructors/me` | 200 para instructor con body válido | Completar perfil instructor |

## Evidencia capturada

Ejemplo de salida (con backend en marcha; si el usuario no existe en DB, login devuelve 401 y se omiten el resto de endpoints):

```
--- QA Endpoint verification ---
BASE_URL=http://localhost:3000 API=http://localhost:3000/api/v1 QA_EMAIL=fig@gmail.com
[POST /auth/login] status=401 body={"message":"Email no encontrado",...}
--- No token/userId; skipping authenticated endpoints. ---
--- End ---
```

Para evidencia completa: crear un usuario en DB (o usar uno existente), setear `QA_EMAIL`/`QA_PASSWORD` y volver a ejecutar el script; pegar la salida aquí.

## Fixes aplicados (si hubo fallos)

- (Listar aquí cualquier cambio mínimo en backend o en ApiService para que los checks pasen.)
- Ejemplo: "GET /users/:id requería auth → se dejó opcional para permitir resolver rol con Bearer."
