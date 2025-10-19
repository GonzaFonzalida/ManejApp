# Módulo de Notificaciones - ManejApp

## Descripción General

El módulo de notificaciones de ManejApp permite enviar notificaciones push a los usuarios de la aplicación utilizando Firebase Cloud Messaging (FCM). Soporta notificaciones individuales, por roles y broadcast a todos los usuarios.

## Arquitectura del Módulo

### Componentes Principales

```
┌─────────────────────────────────────────────────────────────┐
│                    Notification Module                      │
├─────────────────────────────────────────────────────────────┤
│  Controller  │  Service  │  Repository  │  Firebase Config │
├─────────────────────────────────────────────────────────────┤
│                    Database Layer                           │
├─────────────────────────────────────────────────────────────┤
│              NotificationToken Table                        │
└─────────────────────────────────────────────────────────────┘
```

### Estructura de Archivos

```
src/modules/notifications/
├── controller.ts              # Controlador HTTP
├── service.ts                 # Lógica de negocio
├── routes.ts                  # Definición de rutas
├── schemas.ts                 # Validaciones Zod
└── repositories/
    ├── NotificationTokenRepository.ts      # Interface
    └── PrismaNotificationTokenRepository.ts # Implementación
```

## API Endpoints

### 1. Registrar Token FCM
**POST** `/notifications/token`

Registra o actualiza el token FCM de un usuario para recibir notificaciones.

```json
{
  "token": "fcm_token_string_here"
}
```

**Respuesta:**
```json
{
  "message": "Token registered successfully"
}
```

### 2. Enviar Notificación a Usuario Específico
**POST** `/notifications/send-to-user`

Envía una notificación a un usuario específico por su ID.

```json
{
  "userId": 123,
  "title": "Nueva clase programada",
  "body": "Tienes una clase de manejo programada para mañana a las 10:00 AM"
}
```

### 3. Enviar Notificación por Rol
**POST** `/notifications/send-to-role`

Envía notificaciones a todos los usuarios con un rol específico.

```json
{
  "role": "STUDENT",
  "title": "Mantenimiento programado",
  "body": "El sistema estará en mantenimiento el domingo de 2:00 AM a 4:00 AM"
}
```

**Roles disponibles:** `STUDENT`, `INSTRUCTOR`, `ADMIN`

### 4. Enviar Notificación Broadcast
**POST** `/notifications/broadcast`

Envía una notificación a todos los usuarios registrados.

```json
{
  "title": "¡Nueva funcionalidad disponible!",
  "body": "Ahora puedes cancelar clases hasta 2 horas antes del inicio"
}
```

## Configuración de Firebase

### Modo Desarrollo (Mock)
Por defecto, el módulo funciona en modo mock para desarrollo, registrando las notificaciones en los logs sin enviarlas realmente.

### Configuración Producción

1. **Obtener credenciales de Firebase:**
   - Crear proyecto en Firebase Console
   - Generar clave privada del Admin SDK
   - Descargar archivo JSON de credenciales

2. **Configurar variables de entorno:**
```bash
GOOGLE_APPLICATION_CREDENTIALS="path/to/serviceAccountKey.json"
FIREBASE_PROJECT_ID="your-firebase-project-id"
```

3. **Estructura del archivo de credenciales:**
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com",
  "client_id": "client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
```

## Implementación en la Interfaz de Usuario

### 1. Configuración Inicial del Cliente

#### React Native / Expo
```javascript
import messaging from '@react-native-firebase/messaging';

// Solicitar permisos
const requestPermission = async () => {
  const authStatus = await messaging().requestPermission();
  const enabled = authStatus === messaging.AuthorizationStatus.AUTHORIZED ||
                  authStatus === messaging.AuthorizationStatus.PROVISIONAL;
  
  if (enabled) {
    console.log('Permisos de notificación otorgados');
    await registerToken();
  }
};

// Obtener y registrar token FCM
const registerToken = async () => {
  try {
    const token = await messaging().getToken();
    
    // Enviar token al backend
    await fetch('/api/notifications/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${userToken}`
      },
      body: JSON.stringify({ token })
    });
    
    console.log('Token FCM registrado:', token);
  } catch (error) {
    console.error('Error registrando token:', error);
  }
};
```

#### Web (PWA)
```javascript
import { initializeApp } from 'firebase/app';
import { getMessaging, getToken, onMessage } from 'firebase/messaging';

const firebaseConfig = {
  // Tu configuración de Firebase
};

const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

// Registrar Service Worker
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/firebase-messaging-sw.js');
}

// Obtener token
const registerToken = async () => {
  try {
    const token = await getToken(messaging, {
      vapidKey: 'your-vapid-key'
    });
    
    // Enviar al backend
    await fetch('/api/notifications/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${userToken}`
      },
      body: JSON.stringify({ token })
    });
  } catch (error) {
    console.error('Error:', error);
  }
};
```

### 2. Manejo de Notificaciones en Primer Plano

#### React Native
```javascript
import messaging from '@react-native-firebase/messaging';
import { Alert } from 'react-native';

useEffect(() => {
  // Notificaciones en primer plano
  const unsubscribe = messaging().onMessage(async remoteMessage => {
    Alert.alert(
      remoteMessage.notification?.title || 'Notificación',
      remoteMessage.notification?.body || 'Nueva notificación recibida'
    );
  });

  return unsubscribe;
}, []);

// Notificaciones en segundo plano
messaging().setBackgroundMessageHandler(async remoteMessage => {
  console.log('Mensaje en segundo plano:', remoteMessage);
});
```

#### Web
```javascript
// En el componente principal
useEffect(() => {
  onMessage(messaging, (payload) => {
    console.log('Mensaje recibido:', payload);
    
    // Mostrar notificación personalizada
    showNotification(payload.notification);
  });
}, []);

const showNotification = (notification) => {
  // Implementar UI de notificación personalizada
  // Ejemplo: Toast, Modal, etc.
};
```

### 3. Service Worker para Web (firebase-messaging-sw.js)

```javascript
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  // Tu configuración de Firebase
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Mensaje en segundo plano:', payload);
  
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icon-192x192.png',
    badge: '/badge-72x72.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
```

## Casos de Uso Específicos para ManejApp

### 1. Notificaciones para Estudiantes
```javascript
// Recordatorio de clase próxima
const notifyUpcomingClass = async (studentId, classDetails) => {
  await fetch('/api/notifications/send-to-user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId: studentId,
      title: 'Clase de manejo en 1 hora',
      body: `Tu clase con ${classDetails.instructorName} comienza a las ${classDetails.time}`
    })
  });
};

// Confirmación de reserva
const notifyReservationConfirmed = async (studentId, slotDetails) => {
  await fetch('/api/notifications/send-to-user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId: studentId,
      title: 'Reserva confirmada',
      body: `Tu clase del ${slotDetails.date} ha sido confirmada`
    })
  });
};
```

### 2. Notificaciones para Instructores
```javascript
// Nueva reserva recibida
const notifyNewReservation = async (instructorId, studentName) => {
  await fetch('/api/notifications/send-to-user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId: instructorId,
      title: 'Nueva reserva',
      body: `${studentName} ha reservado una clase contigo`
    })
  });
};

// Cancelación de clase
const notifyClassCancellation = async (instructorId, classDetails) => {
  await fetch('/api/notifications/send-to-user', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId: instructorId,
      title: 'Clase cancelada',
      body: `La clase del ${classDetails.date} ha sido cancelada`
    })
  });
};
```

### 3. Notificaciones Administrativas
```javascript
// Mantenimiento del sistema
const notifyMaintenance = async () => {
  await fetch('/api/notifications/broadcast', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      title: 'Mantenimiento programado',
      body: 'El sistema estará en mantenimiento el domingo de 2:00 AM a 4:00 AM'
    })
  });
};

// Nuevas funcionalidades
const notifyNewFeatures = async () => {
  await fetch('/api/notifications/send-to-role', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      role: 'STUDENT',
      title: '¡Nueva funcionalidad!',
      body: 'Ahora puedes ver el historial completo de tus clases'
    })
  });
};
```

## Integración con el Sistema de Reservas

### Ejemplo de Flujo Completo
```javascript
// En el servicio de Schedule
class ScheduleService {
  async reserveSlot(slotId, studentId) {
    // 1. Crear la reserva
    const reservation = await this.createReservation(slotId, studentId);
    
    // 2. Notificar al estudiante
    await this.notificationService.sendToUser(
      studentId,
      'Reserva confirmada',
      `Tu clase del ${reservation.date} ha sido confirmada`
    );
    
    // 3. Notificar al instructor
    const slot = await this.getSlotById(slotId);
    await this.notificationService.sendToUser(
      slot.instructorId,
      'Nueva reserva',
      `Tienes una nueva clase reservada para el ${reservation.date}`
    );
    
    return reservation;
  }
}
```

## Mejores Prácticas

### 1. Manejo de Errores
- Implementar reintentos para notificaciones fallidas
- Registrar errores para debugging
- Tener fallbacks cuando FCM no esté disponible

### 2. Optimización
- Agrupar notificaciones similares
- Implementar rate limiting
- Usar notificaciones silenciosas para actualizaciones de datos

### 3. Experiencia de Usuario
- Solicitar permisos en el momento apropiado
- Personalizar el contenido según el contexto del usuario
- Implementar configuraciones de notificación por usuario

### 4. Seguridad
- Validar tokens FCM antes de almacenar
- Implementar autenticación para endpoints de notificación
- No incluir información sensible en el payload

## Troubleshooting

### Problemas Comunes

1. **Token no se registra:**
   - Verificar permisos de notificación
   - Comprobar configuración de Firebase
   - Revisar logs del cliente

2. **Notificaciones no llegan:**
   - Verificar que el token esté actualizado
   - Comprobar configuración del servidor Firebase
   - Revisar logs del backend

3. **Modo mock activo en producción:**
   - Verificar variables de entorno
   - Comprobar archivo de credenciales
   - Revisar inicialización de Firebase

### Logs Útiles
```bash
# Ver logs de notificaciones
grep "Notification" logs/app.log

# Ver logs de Firebase
grep "Firebase" logs/app.log

# Ver logs de tokens FCM
grep "FCM token" logs/app.log
```

## Conclusión

El módulo de notificaciones de ManejApp proporciona una base sólida para la comunicación en tiempo real con los usuarios. Su implementación flexible permite funcionar tanto en desarrollo (modo mock) como en producción (Firebase real), facilitando el desarrollo y testing de la aplicación.