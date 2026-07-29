import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config_service.dart';
import 'secure_storage.dart';

/// Thrown when the access token is invalid and refresh could not recover the session.
class SessionExpiredException implements Exception {
  const SessionExpiredException([this.message = 'Sesión expirada']);

  final String message;

  @override
  String toString() => message;
}

class SessionManager {
  SessionManager._();

  static final _storage = appSecureStorage;
  static final _sessionExpiredController = StreamController<void>.broadcast();

  static bool _isRefreshing = false;
  static Completer<bool>? _refreshCompleter;

  static Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  // ─── Read ────────────────────────────────────────────────

  static Future<String?> get accessToken => _storage.read(key: 'auth_token');
  static Future<String?> get refreshToken =>
      _storage.read(key: 'refresh_token');
  static Future<String?> get userId => _storage.read(key: 'user_id');
  static Future<String?> get userEmail => _storage.read(key: 'user_email');

  static Future<bool> get hasSession async {
    final token = await accessToken;
    final uid = await userId;
    return token != null && uid != null;
  }

  // ─── Save ────────────────────────────────────────────────

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String email,
    Map<String, dynamic>? session,
  }) async {
    await Future.wait([
      _storage.write(key: 'auth_token', value: accessToken),
      _storage.write(key: 'refresh_token', value: refreshToken),
      _storage.write(key: 'user_id', value: userId),
      _storage.write(key: 'user_email', value: email),
      if (session != null)
        _storage.write(key: 'session_data', value: jsonEncode(session)),
    ]);
  }

  // ─── Remember email (non-sensitive) ──────────────────────

  static Future<void> setRememberEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('remembered_email', email);
    await prefs.setBool('rememberMe', true);
  }

  static Future<void> clearRememberEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remembered_email');
    await prefs.setBool('rememberMe', false);
  }

  static Future<({String? email, bool rememberMe})> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    final email = rememberMe ? prefs.getString('remembered_email') : null;
    return (email: email, rememberMe: rememberMe);
  }

  /// One-time migration: removes any passwords stored in SharedPreferences by
  /// previous versions of the app.
  static Future<void> migrateFromLegacyStorage() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('password')) {
      developer.log('Migrating: removing password from SharedPreferences',
          name: 'SessionManager');
      await prefs.remove('password');
    }

    final oldEmail = prefs.getString('email');
    if (oldEmail != null && !prefs.containsKey('remembered_email')) {
      await prefs.setString('remembered_email', oldEmail);
    }
    if (prefs.containsKey('email')) {
      await prefs.remove('email');
    }
  }

  /// On cold start: refresh access token when a refresh token exists.
  /// Returns false only when the session cannot be restored (missing or expired refresh).
  static Future<bool> warmUpSession({bool notifyOnFailure = false}) async {
    if (!await hasSession) return false;

    final refresh = await refreshToken;
    if (refresh == null || refresh.isEmpty) {
      final access = await accessToken;
      return access != null && access.isNotEmpty;
    }

    return tryRefresh(notifyOnFailure: notifyOnFailure);
  }

  // ─── Refresh ─────────────────────────────────────────────

  /// Attempts to refresh the access token. Returns true if successful.
  /// Thread-safe: concurrent calls wait for the in-progress refresh.
  static Future<bool> tryRefresh({bool notifyOnFailure = true}) async {
    if (_isRefreshing) {
      return _refreshCompleter?.future ?? Future.value(false);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final currentRefresh = await _storage.read(key: 'refresh_token');
      if (currentRefresh == null) {
        developer.log('tryRefresh: no refresh token', name: 'SessionManager');
        _completeRefresh(false, notifyOnFailure: notifyOnFailure);
        return false;
      }

      final baseUrl = '${ConfigService.baseUrl}/api/v1';
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'refreshToken': currentRefresh}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        final sessionData = data['session'] as Map<String, dynamic>?;

        if (newAccess != null) {
          await _storage.write(key: 'auth_token', value: newAccess);
          if (newRefresh != null) {
            await _storage.write(key: 'refresh_token', value: newRefresh);
          }
          if (sessionData != null) {
            await _storage.write(
                key: 'session_data', value: jsonEncode(sessionData));
          }
          developer.log('tryRefresh: success', name: 'SessionManager');
          _completeRefresh(true, notifyOnFailure: notifyOnFailure);
          return true;
        }
      }

      developer.log('tryRefresh: failed (${response.statusCode})',
          name: 'SessionManager');
      _completeRefresh(false, notifyOnFailure: notifyOnFailure);
      return false;
    } catch (e) {
      developer.log('tryRefresh: error $e', name: 'SessionManager');
      _completeRefresh(false, notifyOnFailure: notifyOnFailure);
      return false;
    }
  }

  static void _completeRefresh(bool success, {bool notifyOnFailure = true}) {
    if (!success && notifyOnFailure) {
      _sessionExpiredController.add(null);
    }
    _refreshCompleter?.complete(success);
    _isRefreshing = false;
    _refreshCompleter = null;
  }

  // ─── Logout / Clear ──────────────────────────────────────

  static Future<void> clearSession() async {
    final currentRefresh = await _storage.read(key: 'refresh_token');

    if (currentRefresh != null) {
      try {
        final baseUrl = '${ConfigService.baseUrl}/api/v1';
        final token = await _storage.read(key: 'auth_token');
        await http
            .post(
              Uri.parse('$baseUrl/auth/logout'),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                if (token != null) 'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'refreshToken': currentRefresh}),
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Best-effort: server-side revocation may fail
      }
    }

    await Future.wait([
      _storage.delete(key: 'auth_token'),
      _storage.delete(key: 'refresh_token'),
      _storage.delete(key: 'user_id'),
      _storage.delete(key: 'user_email'),
      _storage.delete(key: 'session_data'),
      _storage.delete(key: 'session_id'),
      _storage.delete(key: 'session_created_at'),
      _storage.delete(key: 'session_expires_at'),
      _storage.delete(key: 'temp_email'),
      _storage.delete(key: 'temp_password'),
      _storage.delete(key: 'pending_role'),
      _storage.delete(key: 'pending_licenseNumber'),
      _storage.delete(key: 'pending_experienceYears'),
    ]);
  }

  static void dispose() {
    _sessionExpiredController.close();
  }
}
