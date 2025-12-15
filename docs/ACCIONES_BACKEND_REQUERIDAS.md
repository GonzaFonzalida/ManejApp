# 🔥 ACCIONES REQUERIDAS PARA EL BACKEND

## 📋 Resumen

Basado en la respuesta del backend, estas son las acciones críticas que se deben implementar.

---

## 🚨 CRÍTICO - Registro y Perfil

### 1. Agregar Campos al Modelo User
```sql
ALTER TABLE users ADD COLUMN profileImage VARCHAR(255);
ALTER TABLE users ADD COLUMN location VARCHAR(255);
ALTER TABLE users ADD COLUMN hourlyRate DECIMAL(10,2);
```

### 2. Crear Endpoint PUT /api/v1/users/:userId
```javascript
router.put('/:userId', auth, async (req, res) => {
  const { name, location, hourlyRate } = req.body;
  await User.update(req.params.userId, { name, location, hourlyRate });
  res.json({ user: updatedUser });
});
```

### 3. Crear Endpoint POST /api/v1/users/:userId/upload-profile-image
```javascript
router.post('/:userId/upload-profile-image', auth, upload.single('profileImage'), async (req, res) => {
  const imagePath = `/uploads/profiles/${req.file.filename}`;
  const imageUrl = `${process.env.BASE_URL}${imagePath}`;
  await User.update(req.params.userId, { profileImage: imagePath });
  res.json({ profileImage: imagePath, profileImageUrl: imageUrl });
});
```

### 4. Crear Endpoint POST /api/v1/students/register
```javascript
router.post('/register', async (req, res) => {
  const { userId } = req.body;
  await Student.create({ userId });
  res.status(201).json({ message: 'Student registered' });
});
```

### 5. Modificar GET /api/v1/users/:userId
Agregar `profileImageUrl` a la respuesta:
```javascript
router.get('/:userId', auth, async (req, res) => {
  const user = await User.findById(req.params.userId);
  res.json({
    ...user,
    profileImageUrl: user.profileImage ? `${process.env.BASE_URL}${user.profileImage}` : null
  });
});
```

### 6. Modificar GET /api/v1/instructors
Agregar `profileImageUrl` en el objeto `user`:
```javascript
router.get('/', auth, async (req, res) => {
  const instructors = await Instructor.findAll({ include: User });
  const result = instructors.map(i => ({
    ...i,
    user: {
      ...i.user,
      profileImageUrl: i.user.profileImage ? `${process.env.BASE_URL}${i.user.profileImage}` : null
    }
  }));
  res.json(result);
});
```

### 7. Corregir POST /api/v1/users/register
Debe devolver `{ token: { id: userId } }`:
```javascript
router.post('/register', async (req, res) => {
  const user = await User.create(req.body);
  res.status(201).json({ token: { id: user.id } });
});
```

---

## ⚠️ IMPORTANTE

### 8. Crear Endpoint GET /api/v1/classes/my-classes
```javascript
router.get('/my-classes', auth, async (req, res) => {
  const userId = req.user.id;
  const classes = await Class.findByUser(userId);
  res.json(classes);
});
```

### 9. Crear Endpoint GET /api/v1/payments/mercadopago/status/:paymentId
```javascript
router.get('/mercadopago/status/:paymentId', auth, async (req, res) => {
  const status = await MercadoPago.getPaymentStatus(req.params.paymentId);
  res.json(status);
});
```

---

## 📝 OPCIONAL (Logs)

### 10. Crear Módulo de Logs
```javascript
router.get('/logs', auth, admin, async (req, res) => {
  const { level, limit = 100, offset = 0 } = req.query;
  const logs = await Log.find({ level, limit, offset });
  res.json({ logs });
});

router.get('/logs/stats', auth, admin, async (req, res) => {
  const stats = await Log.getStats();
  res.json(stats);
});
```

---

## ⚙️ OPCIONAL (Config)

### 11. Crear Endpoint GET /api/v1/config
```javascript
router.get('/config', (req, res) => {
  res.json({
    baseUrl: process.env.BASE_URL || 'http://localhost:3000',
    apiVersion: 'v1'
  });
});
```

---

## 🎯 PRIORIDADES

### ALTA (Hacer YA)
1. ✅ Agregar campos a User (profileImage, location, hourlyRate)
2. ✅ PUT /api/v1/users/:userId
3. ✅ POST /api/v1/users/:userId/upload-profile-image
4. ✅ POST /api/v1/students/register
5. ✅ Modificar GET /api/v1/users/:userId (agregar profileImageUrl)
6. ✅ Modificar GET /api/v1/instructors (agregar profileImageUrl)
7. ✅ Corregir POST /api/v1/users/register

### MEDIA (Hacer pronto)
8. ⚠️ GET /api/v1/classes/my-classes
9. ⚠️ GET /api/v1/payments/mercadopago/status/:paymentId

### BAJA (Opcional)
10. 📝 Módulo de logs
11. ⚙️ GET /api/v1/config

---

## 🧪 TESTING

Después de implementar, probar:

```bash
# 1. Registro
curl -X POST http://72.60.166.178:3000/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","surname":"User","email":"test@test.com","password":"123456","dni":"12345678","birthDate":"2000-01-01","userAgent":"test","deviceId":"test"}'

# Debe devolver: { "token": { "id": 1 } }

# 2. Registro estudiante
curl -X POST http://72.60.166.178:3000/api/v1/students/register \
  -H "Content-Type: application/json" \
  -d '{"userId":1}'

# 3. Actualizar usuario
curl -X PUT http://72.60.166.178:3000/api/v1/users/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Nuevo Nombre","location":"Buenos Aires","hourlyRate":5000}'

# 4. Obtener perfil
curl http://72.60.166.178:3000/api/v1/users/1 \
  -H "Authorization: Bearer TOKEN"

# Debe incluir: "profileImageUrl": "http://72.60.166.178:3000/uploads/profiles/1.jpg"

# 5. Subir imagen
curl -X POST http://72.60.166.178:3000/api/v1/users/1/upload-profile-image \
  -H "Authorization: Bearer TOKEN" \
  -F "profileImage=@foto.jpg"
```

---

## 📊 CHECKLIST

- [ ] Campos agregados a User (profileImage, location, hourlyRate)
- [ ] PUT /api/v1/users/:userId implementado
- [ ] POST /api/v1/users/:userId/upload-profile-image implementado
- [ ] POST /api/v1/students/register implementado
- [ ] GET /api/v1/users/:userId devuelve profileImageUrl
- [ ] GET /api/v1/instructors devuelve profileImageUrl en user
- [ ] POST /api/v1/users/register devuelve { token: { id } }
- [ ] GET /api/v1/classes/my-classes implementado
- [ ] GET /api/v1/payments/mercadopago/status/:paymentId implementado
- [ ] Módulo de logs (opcional)
- [ ] GET /api/v1/config (opcional)

---

## 🚀 RESULTADO ESPERADO

Después de implementar estos cambios:

✅ El registro de alumno funcionará
✅ La edición de perfil funcionará (alumno e instructor)
✅ La subida de imágenes funcionará
✅ Los datos se guardarán correctamente en la BD
✅ El frontend mostrará los datos actualizados

---

## 📞 NOTAS

- Usar `multer` para upload de imágenes
- Crear carpeta `uploads/profiles/` con permisos de escritura
- Agregar `BASE_URL=http://72.60.166.178:3000` en `.env`
- Servir archivos estáticos: `app.use('/uploads', express.static('uploads'))`
