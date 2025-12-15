# 📋 PENDIENTES BACKEND - Análisis Detallado

## 🔍 Análisis de Datos Hardcodeados

### 1. URLs del Backend Hardcodeadas

#### 📍 Ubicaciones Encontradas:

**api_service.dart (Línea 10)**
```dart
static const String _baseUrl = 'http://192.168.0.31:3000/api/v1';
```

**editar_perfil_screen.dart (Línea 56)**
```dart
final fullImageUrl = profileImage != null && profileImage.isNotEmpty
    ? (profileImage.startsWith('http') ? profileImage : 'http://192.168.0.3:3000$profileImage')
    : null;
```

**home_screen.dart (Línea 237)**
```dart
return profileImage.startsWith('http') 
    ? profileImage 
    : 'http://192.168.0.3:3000$profileImage';
```

#### ⚠️ Problemas:
- La URL está hardcodeada en múltiples lugares
- Diferentes IPs en diferentes archivos (192.168.0.31 vs 192.168.0.3)
- Imposible cambiar el servidor sin recompilar la app
- No funciona en producción

---

### 2. IPs Hardcodeadas en Requests

#### 📍 Ubicaciones Encontradas:

**api_service.dart - register() (Línea 27)**
```dart
final userAgent = 'Flutter-Mobile-App/1.0';
final ip = '192.168.0.31';  // ❌ HARDCODEADO
final deviceId = 'flutter-mobile-app';
```

**api_service.dart - login() (Línea 367)**
```dart
final userAgent = 'Flutter-Mobile-App/1.0';
final ip = '192.168.1.1';  // ❌ HARDCODEADO (IP diferente!)
```

#### ⚠️ Problemas:
- El frontend envía IPs falsas/hardcodeadas
- El backend debería extraer la IP real de los headers HTTP
- Inconsistencia: register usa 192.168.0.31, login usa 192.168.1.1

---

### 3. URLs de Imágenes Incompletas

#### 📍 Problema:
El backend devuelve rutas relativas como:
```
/uploads/profiles/123.jpg
```

Pero debería devolver URLs completas:
```
http://192.168.0.31:3000/uploads/profiles/123.jpg
```

#### 💡 Workaround Actual en Frontend:
```dart
// editar_perfil_screen.dart
final fullImageUrl = profileImage.startsWith('http') 
    ? profileImage 
    : 'http://192.168.0.3:3000$profileImage';
```

---

## 🎯 Endpoints Faltantes

### 1. GET /api/v1/config
**Propósito:** Obtener configuración dinámica del servidor

**Respuesta Esperada:**
```json
{
  "baseUrl": "http://192.168.0.31:3000",
  "apiVersion": "v1",
  "environment": "development",
  "features": {
    "mercadoPago": true,
    "notifications": true
  }
}
```

**Ejemplo de Implementación Backend (Node.js/Express):**
```javascript
// routes/config.routes.js
router.get('/config', (req, res) => {
  res.json({
    baseUrl: process.env.BASE_URL || 'http://localhost:3000',
    apiVersion: 'v1',
    environment: process.env.NODE_ENV || 'development',
    features: {
      mercadoPago: process.env.MERCADOPAGO_ENABLED === 'true',
      notifications: process.env.NOTIFICATIONS_ENABLED === 'true'
    }
  });
});
```

---

### 2. Modificar Respuestas de Usuarios/Instructores

#### Endpoints Afectados:
- `GET /api/v1/users/:id`
- `GET /api/v1/instructors`
- `GET /api/v1/auth/me`

#### Cambio Requerido:

**Antes:**
```json
{
  "id": 1,
  "name": "Juan",
  "profileImage": "/uploads/profiles/123.jpg"
}
```

**Después:**
```json
{
  "id": 1,
  "name": "Juan",
  "profileImage": "/uploads/profiles/123.jpg",
  "profileImageUrl": "http://192.168.0.31:3000/uploads/profiles/123.jpg"
}
```

**Ejemplo de Implementación:**
```javascript
// utils/imageHelper.js
function getFullImageUrl(relativePath) {
  if (!relativePath) return null;
  if (relativePath.startsWith('http')) return relativePath;
  const baseUrl = process.env.BASE_URL || 'http://localhost:3000';
  return `${baseUrl}${relativePath}`;
}

// En el controller
const user = await User.findById(userId);
return {
  ...user.toJSON(),
  profileImageUrl: getFullImageUrl(user.profileImage)
};
```

---

### 3. Extraer IP Automáticamente

#### Endpoints Afectados:
- `POST /api/v1/users/register`
- `POST /api/v1/auth/login`

#### Cambio Requerido:

**Middleware para Extraer IP:**
```javascript
// middleware/extractIp.js
function extractClientIp(req) {
  return req.headers['x-forwarded-for']?.split(',')[0].trim() ||
         req.headers['x-real-ip'] ||
         req.connection.remoteAddress ||
         req.socket.remoteAddress ||
         'unknown';
}

module.exports = (req, res, next) => {
  req.clientIp = extractClientIp(req);
  next();
};
```

**Modificar Controllers:**
```javascript
// controllers/auth.controller.js
async register(req, res) {
  const { name, email, password } = req.body;
  
  // ✅ Usar IP del middleware, ignorar la del body
  const ip = req.clientIp;
  const userAgent = req.headers['user-agent'] || 'unknown';
  
  // ... resto del código
}
```

---

## 📝 Variables de Entorno Faltantes

### Backend (.env)
```env
# Server
BASE_URL=http://192.168.0.31:3000
PORT=3000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/manejapp

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# Features
MERCADOPAGO_ENABLED=true
NOTIFICATIONS_ENABLED=true

# File Upload
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=5242880
```

---

## ✅ Checklist Completo de Implementación

### Backend (4 cambios)

#### 1. Crear endpoint /api/v1/config
- [ ] Crear archivo `routes/config.routes.js`
- [ ] Implementar controller que devuelva configuración
- [ ] Agregar variables de entorno necesarias
- [ ] Registrar ruta en app principal
- [ ] Probar endpoint con Postman/curl

**Código:**
```javascript
// routes/config.routes.js
const express = require('express');
const router = express.Router();

router.get('/config', (req, res) => {
  res.json({
    baseUrl: process.env.BASE_URL || 'http://localhost:3000',
    apiVersion: 'v1',
    environment: process.env.NODE_ENV || 'development'
  });
});

module.exports = router;

// En app.js
app.use('/api/v1', require('./routes/config.routes'));
```

#### 2. Agregar profileImageUrl en respuestas
- [ ] Crear helper `utils/imageHelper.js`
- [ ] Modificar `UserController.getProfile()`
- [ ] Modificar `InstructorController.getAll()`
- [ ] Modificar `AuthController.me()`
- [ ] Probar que devuelva URLs completas

**Código:**
```javascript
// utils/imageHelper.js
const getFullImageUrl = (relativePath) => {
  if (!relativePath) return null;
  if (relativePath.startsWith('http')) return relativePath;
  return `${process.env.BASE_URL}${relativePath}`;
};

module.exports = { getFullImageUrl };

// En controllers
const { getFullImageUrl } = require('../utils/imageHelper');

// Agregar en respuesta
profileImageUrl: getFullImageUrl(user.profileImage)
```

#### 3. Extraer IP automáticamente
- [ ] Crear middleware `middleware/extractIp.js`
- [ ] Aplicar middleware globalmente
- [ ] Modificar `AuthController.register()`
- [ ] Modificar `AuthController.login()`
- [ ] Ignorar IP del body, usar `req.clientIp`

**Código:**
```javascript
// middleware/extractIp.js
const extractClientIp = (req) => {
  return req.headers['x-forwarded-for']?.split(',')[0].trim() ||
         req.headers['x-real-ip'] ||
         req.connection.remoteAddress ||
         'unknown';
};

module.exports = (req, res, next) => {
  req.clientIp = extractClientIp(req);
  next();
};

// En app.js
const extractIp = require('./middleware/extractIp');
app.use(extractIp);

// En controllers
const ip = req.clientIp; // ✅ Usar esto
// const ip = req.body.ip; // ❌ NO usar esto
```

#### 4. Agregar variables de entorno
- [ ] Crear/actualizar archivo `.env`
- [ ] Agregar `BASE_URL`
- [ ] Agregar otras variables necesarias
- [ ] Documentar en `.env.example`
- [ ] Reiniciar servidor

---

### Frontend (2 cambios)

#### 1. Crear ConfigService
- [ ] Crear archivo `lib/services/config_service.dart`
- [ ] Implementar método `loadConfig()`
- [ ] Guardar config en memoria
- [ ] Manejar errores y fallback

**Código:**
```dart
// lib/services/config_service.dart
class ConfigService {
  static String? _baseUrl;
  static const String _fallbackUrl = 'http://192.168.0.31:3000';

  static Future<void> loadConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$_fallbackUrl/api/v1/config'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _baseUrl = data['baseUrl'];
      }
    } catch (e) {
      _baseUrl = _fallbackUrl;
    }
  }

  static String get baseUrl => _baseUrl ?? _fallbackUrl;
}
```

#### 2. Modificar ApiService
- [ ] Importar `ConfigService`
- [ ] Cambiar `_baseUrl` a getter dinámico
- [ ] Eliminar concatenación manual de URLs de imágenes
- [ ] Usar `profileImageUrl` del backend
- [ ] Eliminar IPs hardcodeadas en register/login

**Código:**
```dart
// lib/services/api_service.dart
class ApiService {
  // ❌ ANTES
  // static const String _baseUrl = 'http://192.168.0.31:3000/api/v1';
  
  // ✅ DESPUÉS
  static String get _baseUrl => '${ConfigService.baseUrl}/api/v1';

  // En register/login - ELIMINAR estas líneas:
  // final ip = '192.168.0.31'; // ❌ ELIMINAR
  // 'ip': ip, // ❌ ELIMINAR del body
  
  // En pantallas - USAR profileImageUrl:
  // ❌ ANTES
  // final url = 'http://192.168.0.3:3000$profileImage';
  
  // ✅ DESPUÉS
  final url = profile['profileImageUrl'];
}
```

#### 3. Inicializar Config en main.dart
- [ ] Llamar `ConfigService.loadConfig()` antes de `runApp()`
- [ ] Mostrar splash mientras carga
- [ ] Manejar errores de conexión

**Código:**
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.loadConfig();
  runApp(const MyApp());
}
```

---

## 📊 Resumen de Archivos a Modificar

### Backend
1. `routes/config.routes.js` (CREAR)
2. `utils/imageHelper.js` (CREAR)
3. `middleware/extractIp.js` (CREAR)
4. `controllers/user.controller.js` (MODIFICAR)
5. `controllers/instructor.controller.js` (MODIFICAR)
6. `controllers/auth.controller.js` (MODIFICAR)
7. `.env` (MODIFICAR)
8. `app.js` (MODIFICAR - registrar rutas y middleware)

### Frontend
1. `lib/services/config_service.dart` (CREAR)
2. `lib/services/api_service.dart` (MODIFICAR)
3. `lib/screens/editar_perfil_screen.dart` (MODIFICAR)
4. `lib/screens/home_screen.dart` (MODIFICAR)
5. `lib/screens/profile_screen.dart` (MODIFICAR)
6. `lib/main.dart` (MODIFICAR)

---

## 🔧 Orden de Implementación Recomendado

### Fase 1: Backend Base (1 hora)
1. Crear endpoint `/api/v1/config`
2. Agregar variables de entorno
3. Probar endpoint

### Fase 2: Backend Mejoras (1 hora)
1. Crear `imageHelper.js`
2. Modificar controllers para agregar `profileImageUrl`
3. Crear middleware `extractIp.js`
4. Modificar auth controllers

### Fase 3: Frontend (1.5 horas)
1. Crear `ConfigService`
2. Modificar `ApiService`
3. Actualizar pantallas
4. Probar flujo completo

---

## 🧪 Testing

### Backend
```bash
# Probar endpoint de config
curl http://192.168.0.31:3000/api/v1/config

# Probar profileImageUrl en respuesta
curl -H "Authorization: Bearer TOKEN" \
  http://192.168.0.31:3000/api/v1/users/1

# Verificar que IP se extrae correctamente
# (revisar logs del servidor al hacer login)
```

### Frontend
```dart
// Verificar que ConfigService carga correctamente
print('Base URL: ${ConfigService.baseUrl}');

// Verificar que imágenes se cargan con URL completa
print('Image URL: ${profile['profileImageUrl']}');
```

---

## 📈 Beneficios de Implementar Estos Cambios

1. **Flexibilidad**: Cambiar servidor sin recompilar
2. **Seguridad**: IPs reales en logs del servidor
3. **Mantenibilidad**: Código más limpio y centralizado
4. **Escalabilidad**: Fácil migrar a producción
5. **Debugging**: Menos errores de URLs incorrectas

---

## 🚨 Notas Importantes

- **NO** eliminar el fallback URL en `ConfigService` por si falla la carga
- **SIEMPRE** usar HTTPS en producción
- **DOCUMENTAR** las variables de entorno en `.env.example`
- **PROBAR** en diferentes redes antes de desplegar
- **CONSIDERAR** usar un servicio de configuración remota (Firebase Remote Config, etc.)

---

## 📞 Soporte

Si encuentras problemas durante la implementación:
1. Verificar que el backend esté corriendo
2. Revisar logs del servidor
3. Verificar variables de entorno
4. Probar endpoints con Postman
5. Verificar conectividad de red
