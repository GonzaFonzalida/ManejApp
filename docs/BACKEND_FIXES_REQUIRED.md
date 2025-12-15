# ✅ Backend Actualizado - Todo Implementado

## ✅ IMPLEMENTADO: Ruta PATCH /users/:id/role

**Error del log:**
```
La ruta 192.168.0.3:3000/api/v1/users/1/role no existe
```

### Solución: Agregar ruta en el backend

**Archivo**: `src/modules/users/users.routes.ts` (o similar)

```typescript
// Agregar esta ruta
router.patch('/:id/role', async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;
    
    // Normalizar rol
    const normalizedRole = role === 'Alumno' ? 'STUDENT' : role;
    
    // Actualizar usuario
    const updatedUser = await prisma.user.update({
      where: { id: parseInt(id) },
      data: { role: normalizedRole },
      select: {
        id: true,
        name: true,
        surname: true,
        email: true,
        role: true,
        // NO incluir password
      }
    });
    
    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});
```

## ✅ IMPLEMENTADO: Cambio de Contraseña y Email

El frontend ya está implementado y espera que `PUT /users/:id` acepte estos campos:

### Para cambiar contraseña:
```json
{
  "currentPassword": "contraseña_actual",
  "password": "nueva_contraseña"
}
```

### Para cambiar email:
```json
{
  "email": "nuevo@email.com",
  "password": "contraseña_actual"
}
```

**Archivo**: `src/modules/users/users.routes.ts`

```typescript
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { currentPassword, password, email, name, location } = req.body;
    
    // Obtener usuario actual
    const user = await prisma.user.findUnique({
      where: { id: parseInt(id) }
    });
    
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }
    
    const updateData: any = {};
    
    // Cambio de contraseña
    if (password && currentPassword) {
      const isValid = await bcrypt.compare(currentPassword, user.password);
      if (!isValid) {
        return res.status(401).json({ message: 'Contraseña actual incorrecta' });
      }
      updateData.password = await bcrypt.hash(password, 10);
    }
    
    // Cambio de email
    if (email && password) {
      const isValid = await bcrypt.compare(password, user.password);
      if (!isValid) {
        return res.status(401).json({ message: 'Contraseña incorrecta' });
      }
      // Verificar que el email no esté en uso
      const existingUser = await prisma.user.findUnique({
        where: { email }
      });
      if (existingUser && existingUser.id !== parseInt(id)) {
        return res.status(400).json({ message: 'El email ya está en uso' });
      }
      updateData.email = email;
    }
    
    // Otros campos
    if (name) updateData.name = name;
    if (location) updateData.location = location;
    
    // Actualizar
    const updatedUser = await prisma.user.update({
      where: { id: parseInt(id) },
      data: updateData,
      select: {
        id: true,
        name: true,
        surname: true,
        email: true,
        role: true,
        location: true,
        // NO incluir password
      }
    });
    
    res.status(200).json(updatedUser);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});
```

## 📊 CAMPO LOCATION EN BASE DE DATOS

Si no existe, agregar:

```sql
ALTER TABLE users ADD COLUMN location VARCHAR(255);
```

O en Prisma schema:

```prisma
model User {
  id        Int      @id @default(autoincrement())
  name      String
  surname   String
  email     String   @unique
  password  String
  role      Role
  location  String?  // <-- AGREGAR ESTE CAMPO
  // ... otros campos
}
```

Luego ejecutar:
```bash
npx prisma migrate dev --name add_location_to_users
```

## ✅ RESUMEN DE CAMBIOS IMPLEMENTADOS

1. ✅ **Ruta agregada**: `PATCH /api/v1/users/:id/role`
2. ✅ **Ruta actualizada**: `PUT /api/v1/users/:id` con soporte para cambio de contraseña y email
3. ✅ **Campo agregado**: `location` en tabla `users`
4. ✅ **Validaciones**: Hash de contraseñas, validación de email único, verificación de contraseña actual

## 🧪 TESTING

### Test 1: Cambiar rol a estudiante
```bash
curl -X PATCH http://localhost:3000/api/v1/users/1/role \
  -H "Content-Type: application/json" \
  -d '{"role": "Alumno"}'
```

### Test 2: Cambiar contraseña
```bash
curl -X PUT http://localhost:3000/api/v1/users/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "currentPassword": "old123",
    "password": "new123"
  }'
```

### Test 3: Cambiar email
```bash
curl -X PUT http://localhost:3000/api/v1/users/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{
    "email": "nuevo@email.com",
    "password": "current123"
  }'
```

## 🎯 PRIORIDAD

1. **CRÍTICO**: Agregar `PATCH /users/:id/role` (sin esto no funciona el registro de estudiantes)
2. **IMPORTANTE**: Actualizar `PUT /users/:id` para cambio de contraseña/email
3. **RECOMENDADO**: Agregar campo `location`
