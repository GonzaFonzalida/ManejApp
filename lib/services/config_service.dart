import 'dart:convert';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;

/// Puerto único del API en desarrollo local (alinear con `PORT` en `ManejApp/.env`).
const int kDefaultLocalApiPort = 3099;

/// Host público del API en release/profile cuando no hay `--dart-define=API_URL`.
/// Host oficial de producción. Puede reemplazarse puntualmente con
/// `--dart-define=API_URL=https://otra-api.com` para pruebas controladas.
const String kDefaultRemoteApiHost = 'https://api.manejapp.app';

class ConfigService {
  // --dart-define=API_URL=http://TU_IP_LAN:3099  (dispositivo físico o red distinta al emulador)
  static const String _dartDefineUrl = String.fromEnvironment('API_URL');

  /// Host del Mac visto desde el emulador Android (no usar 127.0.0.1 ahí).
  static String get _defaultLocalBaseUrl {
    if (_dartDefineUrl.isNotEmpty) return _dartDefineUrl;
    // Release/profile: backend remoto por defecto. Para API local en debug: `flutter run --dart-define=API_URL=http://127.0.0.1:3099`.
    if (!kDebugMode) return kDefaultRemoteApiHost;
    if (kIsWeb) return 'http://127.0.0.1:$kDefaultLocalApiPort';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$kDefaultLocalApiPort';
    }
    return 'http://127.0.0.1:$kDefaultLocalApiPort';
  }

  static String _baseUrl =
      _dartDefineUrl.isNotEmpty ? _dartDefineUrl : _defaultLocalBaseUrl;
  static String? _googleClientId;

  /// Solo integration_test / harness local: tiene prioridad sobre [_baseUrl] tras [loadConfig].
  static String? _integrationTestBaseUrl;

  /// Anula la base URL (p. ej. mock HTTP en `127.0.0.1`). Pasar `null` para volver al modo normal.
  static void setIntegrationTestBaseUrl(String? url) {
    if (url == null || url.isEmpty) {
      _integrationTestBaseUrl = null;
      return;
    }
    _integrationTestBaseUrl = url.replaceAll(RegExp(r'/$'), '');
  }

  static String get _fallbackUrl => _baseUrl;

  /// En Android, `localhost` / `127.0.0.1` del backend apuntan al emulador, no al host.
  static String _rewriteLocalhostForAndroid(String url) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return url;
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();
    if (host != 'localhost' && host != '127.0.0.1') return url;
    return uri
        .replace(host: '10.0.2.2')
        .toString()
        .replaceAll(RegExp(r'/$'), '');
  }

  /// Intenta cargar googleClientId (y opcionalmente baseUrl) desde el backend.
  /// Si se pasó --dart-define=API_URL, esa URL es autoritativa y no se sobreescribe
  /// con lo que devuelva el backend (porque el backend puede devolver localhost,
  /// que en un dispositivo físico apunta al dispositivo mismo, no al Mac).
  static Future<void> loadConfig() async {
    try {
      final response = await http
          .get(Uri.parse('$_fallbackUrl/api/v1/config'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        _googleClientId = data?['googleClientId'] as String?;

        if (_dartDefineUrl.isEmpty) {
          final returnedBaseUrl =
              (data?['baseUrl'] as String?)?.replaceAll(RegExp(r'/$'), '');
          if (returnedBaseUrl != null && returnedBaseUrl.isNotEmpty) {
            final lower = returnedBaseUrl.toLowerCase();
            final isLocal =
                lower.contains('127.0.0.1') || lower.contains('localhost');
            if (isLocal) {
              _baseUrl = _rewriteLocalhostForAndroid(returnedBaseUrl);
            } else {
              _baseUrl = returnedBaseUrl;
            }
          }
        }
      }
    } catch (_) {
      // mantener _baseUrl (ya sea de --dart-define o el default)
    }
  }

  static String get baseUrl =>
      (_integrationTestBaseUrl != null && _integrationTestBaseUrl!.isNotEmpty)
          ? _integrationTestBaseUrl!
          : _baseUrl;
  static String? get googleClientId => _googleClientId;
}
