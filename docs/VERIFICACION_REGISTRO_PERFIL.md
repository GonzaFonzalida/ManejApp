# ✅ VERIFICACIÓN: Registro y Edición de Perfil

## 🎯 Cambios Implementados

### 1. Mejorado Registro de Alumno
**Archivo:** `lib/services/api_service.dart`

**Cambios:**
- ✅ Agregados logs detallados para debugging
- ✅ Acepta status code 200 y 201 (antes solo 201)
- ✅ Logs muestran URL, data enviada y respuesta

**Logs agregados:**
```dart
developer.log('=== COMPLETE REGISTRATION ===');
developer.log('userId: $userId, role: $role');
developer.log('Registrando estudiante con data: $data');
developer.log('URL: $_baseUrl/students/register');
developer.log('Response status: ${response.statusCode}');
developer.log('Response body: ${response.body}');
```

---

### 2. Mejorado Edición de Perfil
**Archivo:** `lib/screens/editar_perfil_screen.dart`

**Cambios:**
- ✅ Agregados logs detallados en `_loadProfile()`
- ✅ Logs muestran cada paso de carga de datos
- ✅ Verifica si es instructor y carga descripción
- ✅ Muestra errores específicos

**Logs agregados:**
```dart
debugPrint('=== LOADING PROFILE ===');
debugPrint('userId from storage: $userId');
debugPrint('Fetching profile from API...');
debugPrint('Profile received: $profile');
debugPrint('Is instructor: $isInstructor');
debugPrint('Fetching instructor data...');
debugPrint('Instructor description: ${instructor['description']}');
```

---

## 🧪 TESTING

### Probar Registro de Alumno

1. **Abrir la app y registrarse:**
   - Nombre: Test
   - Email: test@test.com
   - Contraseña: 123456
   - DNI: 12345678
   - Fecha nacimiento: 01/01/2000

2. **Seleccionar rol "Alumno"**

3. **Verificar logs en consola:**
```
=== COMPLETE REGISTRATION ===
userId: 1, role: Alumno
Registrando estudiante con data: {userId: 1}
URL: http://72.60.166.178:3000/api/v1/students/register
Response status: 201
Response body: {...}
```

4. **Si falla, verificar:**
   - ¿El endpoint existe en el backend?
   - ¿Devuelve status 200 o 201?
   - ¿Qué dice el error en `Response body`?

---

### Probar Edición de Perfil (Alumno)

1. **Login como alumno**

2. **Ir a Perfil → Editar Perfil**

3. **Verificar logs:**
```
=== LOADING PROFILE ===
userId from storage: 1
Fetching profile from API...
Profile received: {id: 1, name: Test, ...}
Is instructor: false
```

4. **Cambiar datos:**
   - Nombre: Nuevo Nombre
   - Ubicación: Buenos Aires

5. **Guardar y verificar:**
   - ¿Se guardó correctamente?
   - ¿Los datos se actualizan en la BD?
   - ¿Al volver a entrar muestra los nuevos datos?

---

### Probar Edición de Perfil (Instructor)

1. **Login como instructor**

2. **Ir a Perfil → Editar Perfil**

3. **Verificar logs:**
```
=== LOADING PROFILE ===
userId from storage: 2
Fetching profile from API...
Profile received: {id: 2, name: Instructor, role: INSTRUCTOR, ...}
Is instructor: true
Fetching instructor data...
Instructors count: 5
Instructor found: true
Instructor description: Soy un instructor con 10 años de experiencia
```

4. **Cambiar datos:**
   - Nombre: Nuevo Nombre
   - Ubicación: Buenos Aires
   - Tarifa: 5000
   - Descripción: Nueva descripción

5. **Guardar y verificar:**
   - ¿Se guardó el nombre en `users`?
   - ¿Se guardó la descripción en `instructors`?
   - ¿Se guardó la tarifa en `users.hourlyRate`?
   - ¿Al volver a entrar muestra los nuevos datos?

---

## 🔍 DEBUGGING

### Si el registro de alumno falla:

**1. Verificar endpoint en backend:**
```bash
curl -X POST http://72.60.166.178:3000/api/v1/students/register \
  -H "Content-Type: application/json" \
  -d '{"userId":1}'
```

**2. Verificar respuesta:**
- ¿Devuelve 200 o 201?
- ¿Qué dice el mensaje de error?

**3. Verificar en BD:**
```sql
SELECT * FROM students WHERE userId = 1;
```

---

### Si la edición de perfil falla:

**1. Verificar que GET /users/:id devuelve datos correctos:**
```bash
curl http://72.60.166.178:3000/api/v1/users/1 \
  -H "Authorization: Bearer TOKEN"
```

**Debe devolver:**
```json
{
  "id": 1,
  "name": "Test",
  "location": "Buenos Aires",
  "hourlyRate": 5000,
  "profileImage": "/uploads/profiles/1.jpg",
  "profileImageUrl": "http://72.60.166.178:3000/uploads/profiles/1.jpg"
}
```

**2. Verificar que PUT /users/:id actualiza:**
```bash
curl -X PUT http://72.60.166.178:3000/api/v1/users/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Nuevo Nombre","location":"Buenos Aires"}'
```

**3. Para instructores, verificar PUT /instructors/:id:**
```bash
curl -X PUT http://72.60.166.178:3000/api/v1/instructors/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Nueva descripción"}'
```

---

## 📋 CHECKLIST BACKEND

### Registro de Alumno
- [ ] Endpoint `POST /api/v1/students/register` existe
- [ ] Acepta `{ userId: number }`
- [ ] Devuelve status 200 o 201
- [ ] Crea registro en tabla `students`
- [ ] No requiere autenticación (o usa token temporal)

### Edición de Perfil (Alumno)
- [ ] `GET /api/v1/users/:id` devuelve `profileImageUrl`
- [ ] `PUT /api/v1/users/:id` actualiza `name`, `location`
- [ ] `POST /api/v1/users/:id/upload-profile-image` sube imagen
- [ ] Los cambios se guardan en BD
- [ ] Al hacer GET nuevamente, devuelve datos actualizados

### Edición de Perfil (Instructor)
- [ ] `GET /api/v1/users/:id` devuelve `hourlyRate`, `profileImageUrl`
- [ ] `PUT /api/v1/users/:id` actualiza `name`, `location`, `hourlyRate`
- [ ] `GET /api/v1/instructors` devuelve instructor con `description`
- [ ] `PUT /api/v1/instructors/:id` actualiza `description`
- [ ] `POST /api/v1/users/:id/upload-profile-image` sube imagen
- [ ] Los cambios se guardan en BD
- [ ] Al hacer GET nuevamente, devuelve datos actualizados

---

## 🚨 ERRORES COMUNES

### Error: "La ruta /api/v1/students/register no existe"
**Solución:** Crear el endpoint en el backend

### Error: "userId no encontrado"
**Solución:** Verificar que el registro inicial devuelve `{ token: { id: number } }`

### Error: "No se actualizan los datos"
**Solución:** Verificar que el backend hace UPDATE en la BD, no solo devuelve OK

### Error: "La descripción no se guarda"
**Solución:** Verificar que `PUT /instructors/:id` actualiza la tabla `instructors`

---

## ✅ RESULTADO ESPERADO

### Alumno:
1. Registro exitoso
2. Puede editar nombre y ubicación
3. Puede subir foto de perfil
4. Los cambios persisten en la BD
5. Al reabrir la app, ve sus datos actualizados

### Instructor:
1. Registro exitoso
2. Puede editar nombre, ubicación, tarifa y descripción
3. Puede subir foto de perfil
4. Los cambios persisten en la BD
5. Al reabrir la app, ve sus datos actualizados
6. Otros usuarios ven su descripción actualizada

---

## 📞 PRÓXIMOS PASOS

1. **Probar registro de alumno** con los logs activados
2. **Probar edición de perfil** de alumno e instructor
3. **Verificar que los datos persisten** en la BD
4. **Reportar cualquier error** con los logs completos
