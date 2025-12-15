# 📋 ENDPOINTS REQUERIDOS POR EL FRONTEND

## 🎯 Resumen Ejecutivo

El frontend hace **70+ llamadas** a endpoints del backend. Este documento lista TODOS los endpoints que el backend debe implementar.

---

## ✅ ENDPOINTS CRÍTICOS (Registro y Perfil)

### 1. POST /api/v1/users/register
**Usado en:** Registro inicial de usuario

**Body esperado:**
```json
{
  "name": "string",
  "surname": "string", 
  "email": "string",
  "password": "string",
  "dni": "string",
  "birthDate": "YYYY-MM-DD",
  "userAgent": "string",
  "deviceId": "string"
}
```

**Respuesta esperada (201):**
```json
{
  "token": {
    "id": "number"
  }
}
```

---

### 2. POST /api/v1/students/register
**Usado en:** Completar registro como alumno

**Body esperado:**
```json
{
  "userId": "number"
}
```

**Respuesta esperada (201):**
```json
{
  "message": "Student registered successfully"
}
```

---

### 3. POST /api/v1/instructors/register
**Usado en:** Completar registro como instructor

**Body esperado:**
```json
{
  "userId": "number",
  "licenseNumber": "string",
  "experienceYears": "number"
}
```

**Respuesta esperada (201):**
```json
{
  "message": "Instructor registered successfully"
}
```

---

### 4. GET /api/v1/users/:userId
**Usado en:** Obtener perfil de usuario

**Headers:**
```
Authorization: Bearer {token}
```

**Respuesta esperada (200):**
```json
{
  "id": "number",
  "name": "string",
  "surname": "string",
  "email": "string",
  "dni": "string",
  "birthDate": "string",
  "role": "STUDENT|INSTRUCTOR|ADMIN",
  "location": "string",
  "hourlyRate": "number",
  "profileImage": "/uploads/profiles/123.jpg",
  "profileImageUrl": "http://72.60.166.178:3000/uploads/profiles/123.jpg"
}
```

---

### 5. PUT /api/v1/users/:userId
**Usado en:** Actualizar perfil de usuario

**Headers:**
```
Authorization: Bearer {token}
```

**Body esperado:**
```json
{
  "name": "string",
  "location": "string",
  "hourlyRate": "number"
}
```

**Respuesta esperada (200):**
```json
{
  "user": {
    "id": "number",
    "name": "string",
    "location": "string",
    "hourlyRate": "number"
  }
}
```

---

### 6. POST /api/v1/users/:userId/upload-profile-image
**Usado en:** Subir foto de perfil

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body (FormData):**
```
profileImage: File
```

**Respuesta esperada (200/201):**
```json
{
  "message": "Image uploaded successfully",
  "profileImage": "/uploads/profiles/123.jpg",
  "profileImageUrl": "http://72.60.166.178:3000/uploads/profiles/123.jpg"
}
```

---

### 7. GET /api/v1/instructors
**Usado en:** Listar instructores

**Headers:**
```
Authorization: Bearer {token}
```

**Respuesta esperada (200):**
```json
[
  {
    "id": "number",
    "userId": "number",
    "licenseNumber": "string",
    "experienceYears": "number",
    "description": "string",
    "rating": "number",
    "user": {
      "id": "number",
      "name": "string",
      "surname": "string",
      "email": "string",
      "location": "string",
      "hourlyRate": "number",
      "profileImage": "/uploads/profiles/123.jpg",
      "profileImageUrl": "http://72.60.166.178:3000/uploads/profiles/123.jpg"
    }
  }
]
```

---

### 8. PUT /api/v1/instructors/:instructorId
**Usado en:** Actualizar perfil de instructor

**Headers:**
```
Authorization: Bearer {token}
```

**Body esperado:**
```json
{
  "description": "string",
  "licenseNumber": "string",
  "experienceYears": "number"
}
```

**Respuesta esperada (200):**
```json
{
  "message": "Instructor updated successfully"
}
```

---

## 🔐 AUTENTICACIÓN

### 9. POST /api/v1/auth/login
**Body esperado:**
```json
{
  "email": "string",
  "password": "string",
  "userAgent": "string",
  "deviceId": "string"
}
```

**Respuesta esperada (200):**
```json
{
  "accessToken": "string",
  "refreshToken": "string",
  "user": {
    "id": "number"
  }
}
```

### 10. POST /api/v1/auth/logout
### 11. POST /api/v1/auth/refresh
### 12. GET /api/v1/auth/me
### 13. GET /api/v1/auth/sessions
### 14. POST /api/v1/auth/revoke/:sessionId
### 15. POST /api/v1/auth/revoke-all

---

## 🚗 AUTOS

### 16. GET /api/v1/cars
### 17. POST /api/v1/cars
### 18. GET /api/v1/cars/:carId
### 19. PUT /api/v1/cars/:carId
### 20. DELETE /api/v1/cars/:carId

---

## 📚 CLASES

### 21. GET /api/v1/classes
### 22. POST /api/v1/classes
### 23. GET /api/v1/classes/my-classes
### 24. GET /api/v1/classes/:classId
### 25. PUT /api/v1/classes/:classId
### 26. PATCH /api/v1/classes/:classId/cancel
### 27. DELETE /api/v1/classes/:classId

---

## 💰 PAGOS

### 28. GET /api/v1/payments
### 29. GET /api/v1/payments/:paymentId
### 30. GET /api/v1/payments/driving-class/:classId
### 31. PUT /api/v1/payments/:paymentId/status
### 32. POST /api/v1/payments/mercadopago/preference
### 33. GET /api/v1/payments/mercadopago/status/:paymentId

---

## 📅 HORARIOS

### 34. POST /api/v1/schedule/slots
### 35. GET /api/v1/schedule/:slotId
### 36. GET /api/v1/schedule/instructor/:instructorId
### 37. POST /api/v1/schedule/reserve/:slotId
### 38. POST /api/v1/schedule/cancel/:slotId
### 39. DELETE /api/v1/schedule/:slotId

---

## 👥 USUARIOS (Admin)

### 40. GET /api/v1/users/role/:role
### 41. PATCH /api/v1/admin/users/:userId/manage

---

## 📊 ADMIN

### 42. GET /api/v1/admin/dashboard/stats
### 43. GET /api/v1/admin/system/health

---

## 📝 LOGS

### 44. GET /api/v1/logs
### 45. GET /api/v1/logs/stats

---

## ⚙️ CONFIGURACIÓN (OPCIONAL)

### 46. GET /api/v1/config
**Respuesta esperada (200):**
```json
{
  "baseUrl": "http://72.60.166.178:3000",
  "apiVersion": "v1"
}
```

---

## 🔥 ENDPOINTS CRÍTICOS PARA VERIFICAR

### ✅ Registro de Alumno
1. `POST /api/v1/users/register` - Debe devolver `{ token: { id: number } }`
2. `POST /api/v1/students/register` - Debe aceptar `{ userId: number }`

### ✅ Edición de Perfil (Alumno)
1. `GET /api/v1/users/:userId` - Debe devolver `profileImageUrl`
2. `PUT /api/v1/users/:userId` - Debe actualizar `name`, `location`
3. `POST /api/v1/users/:userId/upload-profile-image` - Debe subir imagen

### ✅ Edición de Perfil (Instructor)
1. `GET /api/v1/users/:userId` - Debe devolver `profileImageUrl`, `hourlyRate`
2. `PUT /api/v1/users/:userId` - Debe actualizar `name`, `location`, `hourlyRate`
3. `GET /api/v1/instructors` - Debe devolver instructor con `description`
4. `PUT /api/v1/instructors/:instructorId` - Debe actualizar `description`
5. `POST /api/v1/users/:userId/upload-profile-image` - Debe subir imagen

---

## 📌 NOTAS IMPORTANTES

1. **profileImageUrl**: El backend DEBE devolver la URL completa, no solo la ruta relativa
2. **IPs**: El backend debe extraer la IP de los headers, NO del body
3. **Tokens**: Usar JWT con `id` o `userId` en el payload
4. **CORS**: Permitir requests desde cualquier origen en desarrollo
5. **Multipart**: El endpoint de upload debe aceptar `multipart/form-data`

---

## 🧪 TESTING RÁPIDO

```bash
# 1. Registro
curl -X POST http://72.60.166.178:3000/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","surname":"User","email":"test@test.com","password":"123456","dni":"12345678","birthDate":"2000-01-01","userAgent":"test","deviceId":"test"}'

# 2. Registro alumno
curl -X POST http://72.60.166.178:3000/api/v1/students/register \
  -H "Content-Type: application/json" \
  -d '{"userId":1}'

# 3. Obtener perfil
curl http://72.60.166.178:3000/api/v1/users/1 \
  -H "Authorization: Bearer TOKEN"

# 4. Actualizar perfil
curl -X PUT http://72.60.166.178:3000/api/v1/users/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Nuevo Nombre","location":"Buenos Aires"}'
```
