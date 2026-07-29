import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:manejapp/config/firebase_runtime_options.dart';
import 'package:manejapp/screens/instructor_onboarding_hub_screen.dart';
import 'package:manejapp/screens/instructor_reservation_detail_screen.dart';
import 'package:manejapp/screens/student_reservation_detail_screen.dart';

import 'api_service.dart';
import 'session_manager.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty && FirebaseRuntimeOptions.isConfigured) {
    await FirebaseRuntimeOptions.initialize();
  }
}

class NotificationService {
  NotificationService._();

  static bool _initialized = false;
  static bool _available = false;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static RemoteMessage? _launchMessage;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;

  static bool get isAvailable => _available;

  static void attachNavigator(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!FirebaseRuntimeOptions.isConfigured) {
      developer.log(
        'Firebase no configurado para esta plataforma.',
        name: 'NotificationService',
      );
      return;
    }

    try {
      await FirebaseRuntimeOptions.initialize();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      _launchMessage = await messaging.getInitialMessage();
      _foregroundSubscription =
          FirebaseMessaging.onMessage.listen(_showForegroundMessage);
      _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => navigateFromData(message.data),
      );
      _tokenRefreshSubscription =
          messaging.onTokenRefresh.listen((token) async {
        if (await SessionManager.hasSession) {
          await ApiService.saveFcmToken(token);
        }
      });
      _available = true;
    } catch (error, stackTrace) {
      _available = false;
      developer.log(
        'No se pudo iniciar Firebase; las notificaciones quedan deshabilitadas.',
        name: 'NotificationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<bool> requestPermissionAndRegister() async {
    if (!_available || !await SessionManager.hasSession) return false;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return false;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return false;
    await ApiService.saveFcmToken(token);
    return true;
  }

  static Future<void> registerTokenWithBackendIfLoggedIn() async {
    try {
      await requestPermissionAndRegister();
    } catch (error, stackTrace) {
      developer.log(
        'No se pudo registrar el dispositivo para push.',
        name: 'NotificationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> onLogout() async {
    if (!_available) return;
    await ApiService.deleteFcmTokenRemote();
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  static Future<void> consumeLaunchNotification() async {
    final message = _launchMessage;
    _launchMessage = null;
    if (message != null) navigateFromData(message.data);
  }

  static Future<String?> getToken() async {
    if (!_available) return null;
    return FirebaseMessaging.instance.getToken();
  }

  static Future<void> deleteToken() async {
    if (_available) await FirebaseMessaging.instance.deleteToken();
  }

  static void _showForegroundMessage(RemoteMessage message) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;
    final title = message.notification?.title ?? 'ManejApp';
    final body = message.notification?.body ?? 'Tenés una actualización';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title\n$body'),
        action: message.data.isEmpty
            ? null
            : SnackBarAction(
                label: 'Ver',
                onPressed: () => navigateFromData(message.data),
              ),
      ),
    );
  }

  static void navigateFromData(Map<String, dynamic> data) {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    final type = data['type']?.toString() ?? '';
    final bookingId = int.tryParse(data['bookingId']?.toString() ?? '');

    if (bookingId != null &&
        (type == 'student_booking' || data['role']?.toString() == 'STUDENT')) {
      nav.push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              StudentReservationDetailScreen(reservationId: bookingId),
        ),
      );
      return;
    }
    if (bookingId != null &&
        (type == 'instructor_booking' ||
            data['role']?.toString() == 'INSTRUCTOR')) {
      nav.push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              InstructorReservationDetailScreen(reservationId: bookingId),
        ),
      );
      return;
    }

    if (type == 'instructor_doc' || type == 'instructor_approved') {
      nav.pushNamed(InstructorOnboardingHubScreen.routeName);
    }
  }

  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}
