# 📱 Notificaciones y Onboarding

## 🔔 Estado de Notificaciones

### ¿Funcionan las notificaciones?

**Respuesta: Parcialmente** ⚠️

#### Lo que SÍ funciona:
- ✅ Inicialización de Firebase Messaging
- ✅ Solicitud de permisos
- ✅ Obtención de FCM token
- ✅ Notificaciones locales configuradas
- ✅ Manejo de notificaciones en foreground
- ✅ Manejo de tap en notificaciones

#### Lo que NO funciona (falta backend):
- ❌ Guardar token en backend (`ApiService.saveNotificationToken()` comentado)
- ❌ Envío de notificaciones desde backend
- ❌ Notificaciones de nuevos mensajes
- ❌ Notificaciones de clases reservadas
- ❌ Notificaciones de pagos

### Para que funcionen completamente:

**Backend necesita:**
```typescript
// Endpoint para guardar token
POST /api/v1/notifications/token
Body: { token: string, userId: number }

// Endpoint para enviar notificación
POST /api/v1/notifications/send
Body: { 
  userId: number, 
  title: string, 
  body: string, 
  data?: object 
}
```

**Frontend ya tiene:**
```dart
// En notification_service.dart línea 54
static Future<void> _saveTokenToBackend(String token) async {
  await storage.write(key: 'fcm_token', value: token);
  // TODO: Descomentar cuando backend esté listo
  // await ApiService.saveNotificationToken(token);
}
```

### Configuración en Settings:
- ✅ Switch de notificaciones funciona
- ✅ Guarda preferencias en storage
- ❌ No se comunica con backend (falta implementar)

## 📖 Onboarding - CORREGIDO

### Problema Anterior:
El onboarding aparecía cada vez que cerrabas sesión porque usaba `onboarding_completed` que se borraba en logout.

### Solución Implementada:
Ahora usa `first_launch_completed` que **NUNCA** se borra.

```dart
// En main.dart
final firstLaunch = await storage.read(key: 'first_launch_completed');
if (firstLaunch != 'true') {
  await storage.write(key: 'first_launch_completed', value: 'true');
  // Mostrar onboarding
}
```

### Comportamiento Actual:
- ✅ Primera vez que instalas la app → Muestra onboarding
- ✅ Cierras sesión → NO muestra onboarding
- ✅ Desinstalar y reinstalar → Muestra onboarding (storage se limpia)
- ✅ Botón "Saltar" funciona
- ✅ Botón "Comenzar" funciona

## 🔧 Para Activar Notificaciones Completas

### 1. Backend debe implementar:
```typescript
// routes/notifications.ts
router.post('/token', async (req, res) => {
  const { token, userId } = req.body;
  // Guardar token en DB asociado al usuario
});

router.post('/send', async (req, res) => {
  const { userId, title, body, data } = req.body;
  // Obtener token del usuario
  // Enviar notificación via Firebase Admin SDK
});
```

### 2. Frontend descomentar:
```dart
// En notification_service.dart línea 56
await ApiService.saveNotificationToken(token);
```

### 3. Agregar método en ApiService:
```dart
static Future<void> saveNotificationToken(String token) async {
  final authToken = await storage.read(key: 'auth_token');
  final userId = await storage.read(key: 'user_id');
  
  await http.post(
    Uri.parse('$_baseUrl/notifications/token'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
    },
    body: jsonEncode({'token': token, 'userId': int.parse(userId!)}),
  );
}
```

## 📊 Resumen

| Funcionalidad | Estado | Notas |
|--------------|--------|-------|
| Onboarding solo 1ra vez | ✅ | Corregido |
| Permisos notificaciones | ✅ | Funciona |
| FCM Token | ✅ | Se obtiene |
| Notificaciones locales | ✅ | Funciona |
| Guardar token backend | ❌ | Falta endpoint |
| Enviar notificaciones | ❌ | Falta backend |
| Settings notificaciones | ⚠️ | Solo local |

## 🚀 Próximos Pasos

1. Backend implementar endpoints de notificaciones
2. Descomentar `saveNotificationToken()` en frontend
3. Agregar método en ApiService
4. Probar envío de notificaciones desde backend
5. Implementar notificaciones automáticas (nuevos mensajes, clases, pagos)
