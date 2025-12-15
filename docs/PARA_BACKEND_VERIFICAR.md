# 🔍 BACKEND: Verificar Estos Endpoints

## 📋 Instrucciones

**Backend:** Revisá esta lista y decime qué endpoints te faltan o cuáles devuelven datos diferentes.

---

## ✅ ENDPOINTS QUE EL FRONT USA

### 🔐 AUTENTICACIÓN

```
POST   /api/v1/users/register
POST   /api/v1/auth/login
POST   /api/v1/auth/logout
POST   /api/v1/auth/refresh
GET    /api/v1/auth/me
GET    /api/v1/auth/sessions
POST   /api/v1/auth/revoke/:sessionId
POST   /api/v1/auth/revoke-all
```

---

### 👤 USUARIOS

```
GET    /api/v1/users/:userId
PUT    /api/v1/users/:userId
POST   /api/v1/users/:userId/upload-profile-image
GET    /api/v1/users/role/:role
```

---

### 🎓 ESTUDIANTES

```
POST   /api/v1/students/register
```

---

### 👨‍🏫 INSTRUCTORES

```
POST   /api/v1/instructors/register
GET    /api/v1/instructors
PUT    /api/v1/instructors/:instructorId
```

---

### 🚗 AUTOS

```
GET    /api/v1/cars
POST   /api/v1/cars
GET    /api/v1/cars/:carId
PUT    /api/v1/cars/:carId
DELETE /api/v1/cars/:carId
```

---

### 📚 CLASES

```
GET    /api/v1/classes
POST   /api/v1/classes
GET    /api/v1/classes/my-classes
GET    /api/v1/classes/:classId
PUT    /api/v1/classes/:classId
PATCH  /api/v1/classes/:classId/cancel
DELETE /api/v1/classes/:classId
```

---

### 💰 PAGOS

```
GET    /api/v1/payments
GET    /api/v1/payments/:paymentId
GET    /api/v1/payments/driving-class/:classId
PUT    /api/v1/payments/:paymentId/status
POST   /api/v1/payments/mercadopago/preference
GET    /api/v1/payments/mercadopago/status/:paymentId
```

---

### 📅 HORARIOS

```
POST   /api/v1/schedule/slots
GET    /api/v1/schedule/:slotId
GET    /api/v1/schedule/instructor/:instructorId
POST   /api/v1/schedule/reserve/:slotId
POST   /api/v1/schedule/cancel/:slotId
DELETE /api/v1/schedule/:slotId
```

---

### 👑 ADMIN

```
GET    /api/v1/admin/dashboard/stats
GET    /api/v1/admin/system/health
PATCH  /api/v1/admin/users/:userId/manage
```

---

### 📝 LOGS

```
GET    /api/v1/logs
GET    /api/v1/logs/stats
```

---

### ⚙️ CONFIGURACIÓN (OPCIONAL)

```
GET    /api/v1/config
```

---

## 🔥 DATOS QUE EL FRONT ESPERA

### GET /api/v1/users/:userId debe devolver:
```json
{
  "id": 1,
  "name": "Juan",
  "surname": "Perez",
  "email": "juan@test.com",
  "dni": "12345678",
  "birthDate": "2000-01-01",
  "role": "STUDENT",
  "location": "Buenos Aires",
  "hourlyRate": 5000,
  "profileImage": "/uploads/profiles/1.jpg",
  "profileImageUrl": "http://72.60.166.178:3000/uploads/profiles/1.jpg"
}
```

**⚠️ IMPORTANTE:** Debe incluir `profileImageUrl` con la URL completa.

---

### GET /api/v1/instructors debe devolver:
```json
[
  {
    "id": 1,
    "userId": 2,
    "licenseNumber": "ABC123",
    "experienceYears": 10,
    "description": "Instructor con 10 años de experiencia",
    "rating": 4.5,
    "user": {
      "id": 2,
      "name": "Carlos",
      "surname": "Lopez",
      "email": "carlos@test.com",
      "location": "Buenos Aires",
      "hourlyRate": 5000,
      "profileImage": "/uploads/profiles/2.jpg",
      "profileImageUrl": "http://72.60.166.178:3000/uploads/profiles/2.jpg"
    }
  }
]
```

**⚠️ IMPORTANTE:** Debe incluir el objeto `user` completo con `profileImageUrl`.

---

### POST /api/v1/users/register debe aceptar:
```json
{
  "name": "Juan",
  "surname": "Perez",
  "email": "juan@test.com",
  "password": "123456",
  "dni": "12345678",
  "birthDate": "2000-01-01",
  "userAgent": "Flutter-Mobile-App/1.0",
  "deviceId": "flutter-mobile-app"
}
```

**Y devolver:**
```json
{
  "token": {
    "id": 1
  }
}
```

**⚠️ IMPORTANTE:** Debe devolver el `id` del usuario creado dentro de `token`.

---

### POST /api/v1/students/register debe aceptar:
```json
{
  "userId": 1
}
```

**Y devolver status 200 o 201.**

---

### PUT /api/v1/users/:userId debe aceptar:
```json
{
  "name": "Nuevo Nombre",
  "location": "Buenos Aires",
  "hourlyRate": 5000
}
```

**Y actualizar la BD.**

---

### PUT /api/v1/instructors/:instructorId debe aceptar:
```json
{
  "description": "Nueva descripción",
  "licenseNumber": "XYZ789",
  "experienceYears": 15
}
```

**Y actualizar la BD.**

---

### POST /api/v1/users/:userId/upload-profile-image

**Debe aceptar:**
- Content-Type: `multipart/form-data`
- Campo: `profileImage` (archivo)

**Y devolver:**
```json
{
  "message": "Image uploaded successfully",
  "profileImage": "/uploads/profiles/1.jpg",
  "profileImageUrl": "http://72.60.166.178:3000/uploads/profiles/1.jpg"
}
```

---

## ❓ PREGUNTAS PARA EL BACKEND

1. ¿Cuáles de estos endpoints NO existen?
2. ¿Cuáles devuelven datos diferentes a los esperados?
3. ¿El endpoint `GET /api/v1/users/:userId` incluye `profileImageUrl`?
4. ¿El endpoint `GET /api/v1/instructors` incluye el objeto `user` completo?
5. ¿El endpoint `POST /api/v1/students/register` existe y funciona?
6. ¿Los endpoints de actualización (PUT) realmente guardan en la BD?

---

## 🧪 TESTING RÁPIDO

```bash
# 1. Verificar registro
curl -X POST http://72.60.166.178:3000/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","surname":"User","email":"test@test.com","password":"123456","dni":"12345678","birthDate":"2000-01-01","userAgent":"test","deviceId":"test"}'

# 2. Verificar registro de estudiante
curl -X POST http://72.60.166.178:3000/api/v1/students/register \
  -H "Content-Type: application/json" \
  -d '{"userId":1}'

# 3. Verificar perfil de usuario
curl http://72.60.166.178:3000/api/v1/users/1 \
  -H "Authorization: Bearer TOKEN"

# 4. Verificar lista de instructores
curl http://72.60.166.178:3000/api/v1/instructors \
  -H "Authorization: Bearer TOKEN"
```

---

## 📝 RESPUESTA ESPERADA DEL BACKEND

Por favor, respondé con:

```
✅ Endpoint existe y funciona
❌ Endpoint NO existe
⚠️ Endpoint existe pero devuelve datos diferentes
```

**Ejemplo:**
```
✅ POST /api/v1/users/register
❌ POST /api/v1/students/register
⚠️ GET /api/v1/users/:userId (no devuelve profileImageUrl)
✅ GET /api/v1/instructors
```
