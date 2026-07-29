import 'package:http/http.dart' as http;
import 'config_service.dart';

/// Servicio para verificar conectividad con el backend y ejecutar requests con reintento.
class ConnectivityService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _requestTimeout = Duration(seconds: 10);

  static String get _backendUrl => ConfigService.baseUrl;

  /// Verifica si el backend está disponible.
  static Future<bool> isBackendAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/health'))
          .timeout(_requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Ejecuta un request con reintentos ante errores de conexión.
  static Future<http.Response> getWithRetry(Uri url,
      {Map<String, String>? headers}) async {
    return _requestWithRetry(
        () => http.get(url, headers: headers).timeout(_requestTimeout));
  }

  static Future<http.Response> postWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) async {
    final t = timeout ?? _requestTimeout;
    return _requestWithRetry(
      () => http.post(url, headers: headers, body: body).timeout(t),
    );
  }

  static Future<http.Response> putWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return _requestWithRetry(
      () =>
          http.put(url, headers: headers, body: body).timeout(_requestTimeout),
    );
  }

  static Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() request,
  ) async {
    Exception? lastError;
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await request();
        return response;
      } on http.ClientException catch (e) {
        lastError = e;
        if (attempt < _maxRetries) {
          await Future<void>.delayed(_retryDelay);
        }
      } on Exception catch (e) {
        lastError = e;
        if (attempt < _maxRetries) {
          await Future<void>.delayed(_retryDelay);
        }
      }
    }
    throw lastError ?? Exception('Error de conexión');
  }

  /// Mensaje de error estándar cuando el backend no responde.
  static String get connectionErrorMessage =>
      'No se pudo conectar con el servidor.\n\n'
      'Iniciá el backend en una terminal (API en puerto 3099; emulador Android usa 10.0.2.2:3099 automáticamente):\n'
      '  cd ManejApp && pnpm run dev\n\n'
      'Para liberar 3000/3099 antes: pnpm run kill:ports (desde ManejApp/)';
}
