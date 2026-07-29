import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:manejapp/services/notification_service.dart';

class DeepLinkService {
  static StreamSubscription? _sub;
  static final _appLinks = AppLinks();
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _handleInitialUri();
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleUri(uri);
    });
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
    _navigatorKey = null;
  }

  static Future<void> _handleInitialUri() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleUri(uri);
    } catch (e) {
      debugPrint('Error getting initial URI: $e');
    }
  }

  static void _handleUri(Uri uri) {
    final isEmailVerification = uri.scheme == 'manejapp' &&
        (uri.host == 'verify-email' || uri.path == '/verify-email');
    if (isEmailVerification) {
      final token = uri.queryParameters['token'];
      if (token != null) {
        _navigatorKey?.currentState
            ?.pushNamed('/verify-email', arguments: token);
      }
      return;
    }

    final isPasswordReset = uri.scheme == 'manejapp' &&
        (uri.host == 'reset-password' || uri.path == '/reset-password');
    if (isPasswordReset) {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _navigatorKey?.currentState
            ?.pushNamed('/reset-password', arguments: token);
      }
      return;
    }

    if (uri.scheme == 'manejapp' && uri.host == 'booking') {
      NotificationService.navigateFromData({
        'type': uri.queryParameters['role'] == 'INSTRUCTOR'
            ? 'instructor_booking'
            : 'student_booking',
        'role': uri.queryParameters['role'] ?? 'STUDENT',
        'bookingId': uri.queryParameters['bookingId'] ?? '',
      });
      return;
    }

    if (uri.scheme == 'manejapp' && uri.host == 'instructor-onboarding') {
      NotificationService.navigateFromData({
        'type': 'instructor_doc',
        'role': 'INSTRUCTOR',
      });
    }
  }
}
