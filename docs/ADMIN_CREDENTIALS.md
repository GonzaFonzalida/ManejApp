# Credenciales de Administrador

## Usuario Admin por Defecto

**Email:** `admin@gmail.com`  
**Contraseña:** `Admin123!`  
**Rol:** `ADMIN`

## Instrucciones para el Backend

El backend debe crear este usuario admin automáticamente al iniciar la aplicación si no existe.

### Script SQL para crear el admin:

```sql
-- Insertar usuario admin si no existe
INSERT INTO users (email, password, name, surname, dni, birth_date, role, is_active, created_at, updated_at)
SELECT 
  'admin@gmail.com',
  -- Hash de 'Admin123!' (debe ser hasheado con bcrypt en el backend)
  '$2b$10$YourHashedPasswordHere',
  'Administrador',
  'Sistema',
  '00000000',
  '1990-01-01',
  'ADMIN',
  true,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM users WHERE email = 'admin@gmail.com'
);
```

### Código Node.js para crear el admin:

```javascript
import bcrypt from 'bcrypt';
import { prisma } from './prisma';

async function createAdminUser() {
  const adminEmail = 'admin@gmail.com';
  
  // Verificar si ya existe
  const existingAdmin = await prisma.user.findUnique({
    where: { email: adminEmail }
  });
  
  if (existingAdmin) {
    console.log('Admin user already exists');
    return;
  }
  
  // Crear admin
  const hashedPassword = await bcrypt.hash('Admin123!', 10);
  
  await prisma.user.create({
    data: {
      email: adminEmail,
      password: hashedPassword,
      name: 'Administrador',
      surname: 'Sistema',
      dni: '00000000',
      birthDate: new Date('1990-01-01'),
      role: 'ADMIN',
      isActive: true,
    }
  });
  
  console.log('Admin user created successfully');
}

// Ejecutar al iniciar la aplicación
createAdminUser().catch(console.error);
```

## Funcionalidades del Admin

El usuario admin tiene acceso a:

1. **Dashboard**: Estadísticas generales del sistema
2. **Gestión de Usuarios**: Ver, activar/desactivar usuarios
3. **Reportes**: Análisis de pagos, clases, comisiones
4. **Configuración**: Ajustes del sistema
5. **Salud del Sistema**: Monitoreo de problemas

## Endpoints Disponibles

- `GET /api/v1/admin/dashboard/stats` - Estadísticas del dashboard
- `GET /api/v1/admin/system/health` - Estado del sistema
- `PATCH /api/v1/admin/users/:userId/manage` - Gestionar usuarios

## Seguridad

⚠️ **IMPORTANTE**: 
- Cambiar la contraseña por defecto en producción
- Implementar autenticación de dos factores para admin
- Registrar todas las acciones del admin en logs
- Limitar intentos de login para la cuenta admin
