# Checklist QA E2E — Ruteo por rol

Verificación manual de que el ruteo inicial y post-login respetan el rol real en DB (INSTRUCTOR nunca cae en HomeScreen “Buscar instructor”, STUDENT sí) y que no hay loaders infinitos.

## Requisitos previos

- Backend en marcha (`npm run dev` en el repo backend).
- Flutter: `flutter run -d chrome` (web) o dispositivo/emulador (mobile).
- Usuario de prueba STUDENT y otro INSTRUCTOR (o uno que pueda cambiar de rol para las pruebas).

---

## 1. Limpiar storage (web / mobile)

### Web (Chrome)

- DevTools → Application → Storage → Clear site data (o solo Local Storage / Session Storage si la app usa eso para algo además de Flutter).
- O en la app: cerrar sesión (Logout) para limpiar token y user_id del secure storage usado en web.

### Mobile (Android/iOS)

- Desinstalar y reinstalar la app, o desde la app: Logout.
- Flutter Secure Storage se limpia al desinstalar; con Logout se borran las keys que la app escribe (auth_token, user_id, etc.).

---

## 2. Flow INSTRUCTOR

1. Limpiar storage y abrir la app.
2. Iniciar sesión con un usuario que en DB tenga `role = INSTRUCTOR`.
3. **Esperado**: no se muestra nunca la pantalla “Buscar instructor” (HomeScreen). Se muestra:
   - **CompleteInstructorProfile** si el perfil de instructor está incompleto (falta licenseNumber, experienceYears, lat/lng, isListed).
   - **InstructorDashboard** si el perfil está completo.
4. Completar perfil si corresponde (lat, lng, isListed, addressText, etc.) y guardar.
5. **Esperado**: redirección a InstructorDashboard.
6. Reiniciar la app (sin logout). **Esperado**: se abre directo en InstructorDashboard (o CompleteInstructorProfile si aún incompleto), nunca en HomeScreen.

---

## 3. Flow STUDENT

1. Limpiar storage y abrir la app.
2. Iniciar sesión con un usuario que en DB tenga `role = STUDENT`.
3. **Esperado**: se muestra la pantalla “Buscar instructor” (HomeScreen).
4. Reiniciar la app (sin logout). **Esperado**: se abre directo en HomeScreen.

---

## 4. Restart routing

1. Con sesión iniciada (STUDENT o INSTRUCTOR), cerrar la app por completo y volver a abrirla.
2. **Esperado**: la ruta inicial es la correcta según rol en DB (STUDENT → Home, INSTRUCTOR → CompleteInstructorProfile o InstructorDashboard).
3. No debe haber loader infinito; si hay error de red, debe mostrarse Login o un mensaje claro, no quedar colgado.

---

## 5. Simulación JWT stale / rol mismatch

Objetivo: comprobar que el resolver usa el rol de la DB (`GET /users/:id`) y no el rol del JWT.

1. Iniciar sesión como **STUDENT** en la app. Comprobar que se ve HomeScreen.
2. Sin cerrar sesión en la app, cambiar el rol en la base de datos a INSTRUCTOR (el JWT seguirá diciendo STUDENT):

   **Opción A — Prisma (Node):**

   ```bash
   cd /path/to/ManejApp  # repo backend
   npx prisma db execute --stdin <<< "UPDATE \"User\" SET role = 'INSTRUCTOR' WHERE id = <USER_ID>;"
   ```

   Reemplazar `<USER_ID>` por el id del usuario (ej. 2).

   **Opción B — SQL directo:**

   ```bash
   psql "$DATABASE_URL" -c "UPDATE \"User\" SET role = 'INSTRUCTOR' WHERE id = <USER_ID>;"
   ```

3. En la app: reiniciar (cerrar y abrir) o navegar a una pantalla que vuelva a llamar a `RoleRouter.resolveRouteForCurrentUser` (por ejemplo desde Ajustes o perfil, según cómo esté implementado el flujo).
4. **Esperado**: la app debe llevar al usuario por el flujo INSTRUCTOR (CompleteInstructorProfile o InstructorDashboard), no a HomeScreen, porque el resolver lee el rol desde `GET /users/:id`.

---

## 6. Error handling (backend caído / baseUrl incorrecto)

1. Apagar el backend o cambiar en la app la baseUrl a una URL inválida (si tenés forma de configurarlo en debug).
2. Abrir la app con sesión ya guardada (token y user_id en storage).
3. **Esperado**: `auth/me` o las llamadas siguientes fallan; el resolver debe enviar a **Login** (no loader infinito).
4. Con storage limpio y backend caído, abrir la app. **Esperado**: se muestra Login (o pantalla de error de conexión según implementación), no loader infinito.

---

## Resumen de evidencia

| Caso | Resultado (OK / Fallo) | Notas |
|------|------------------------|--------|
| 2. Flow INSTRUCTOR | | |
| 3. Flow STUDENT | | |
| 4. Restart routing | | |
| 5. JWT stale → INSTRUCTOR path | | |
| 6. Backend caído → Login, no loader infinito | | |

Completar la tabla al ejecutar el checklist y adjuntar capturas o logs si hay fallos.
