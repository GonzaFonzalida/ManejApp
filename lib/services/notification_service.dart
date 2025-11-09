import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

const storage = FlutterSecureStorage();

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Solicitar permisos
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Configurar notificaciones locales
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      
      await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Obtener token
      final token = await _messaging.getToken();
      if (token != null) {
        developer.log('FCM Token: $token', name: 'NotificationService');
        await _saveTokenToBackend(token);
      }

      // Escuchar cambios de token
      _messaging.onTokenRefresh.listen(_saveTokenToBackend);

      // Manejar mensajes en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Manejar mensajes cuando la app se abre desde notificación
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      _initialized = true;
      developer.log('Notification service initialized', name: 'NotificationService');
    } catch (e) {
      developer.log('Error initializing notifications: $e', name: 'NotificationService');
    }
  }

  static Future<void> _saveTokenToBackend(String token) async {
    try {
      await storage.write(key: 'fcm_token', value: token);
      // Aquí llamarías a tu API para guardar el token
      // await ApiService.saveNotificationToken(token);
      developer.log('Token saved: $token', name: 'NotificationService');
    } catch (e) {
      developer.log('Error saving token: $e', name: 'NotificationService');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    developer.log('Foreground message: ${message.notification?.title}', name: 'NotificationService');
    
    const androidDetails = AndroidNotificationDetails(
      'manejapp_channel',
      'ManejApp Notifications',
      channelDescription: 'Notificaciones de ManejApp',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'ManejApp',
      message.notification?.body ?? '',
      details,
      payload: message.data.toString(),
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    developer.log('Message opened app: ${message.data}', name: 'NotificationService');
    // Aquí puedes navegar a una pantalla específica según el tipo de notificación
  }

  static void _onNotificationTap(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}', name: 'NotificationService');
    // Manejar tap en notificación
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> deleteToken() async {
    await _messaging.deleteToken();
    await storage.delete(key: 'fcm_token');
  }
}
