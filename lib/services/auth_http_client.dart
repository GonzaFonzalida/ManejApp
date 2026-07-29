import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import 'session_manager.dart';

/// HTTP client that transparently handles authentication:
/// - Attaches Bearer token to every request
/// - On 401, attempts a single token refresh and retries the original request
/// - On refresh failure, fires [SessionManager.onSessionExpired]
///
/// Does NOT intercept non-authenticated requests (use [http] directly for those).
class AuthHttpClient {
  AuthHttpClient._();

  // ─── Public API ──────────────────────────────────────────

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _withAuthRetry(
      (h) => http.get(url, headers: h).timeout(timeout),
      extraHeaders: headers,
    );
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _withAuthRetry(
      (h) => http.post(url, headers: h, body: body).timeout(timeout),
      extraHeaders: headers,
    );
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _withAuthRetry(
      (h) => http.put(url, headers: h, body: body).timeout(timeout),
      extraHeaders: headers,
    );
  }

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _withAuthRetry(
      (h) => http.patch(url, headers: h, body: body).timeout(timeout),
      extraHeaders: headers,
    );
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _withAuthRetry(
      (h) => http.delete(url, headers: h).timeout(timeout),
      extraHeaders: headers,
    );
  }

  // ─── Internals ───────────────────────────────────────────

  /// Marker header so the retry does not trigger an infinite loop.
  static const _retryHeader = 'X-Auth-Retry';

  static Future<Map<String, String>> _buildHeaders(
      Map<String, String>? extra) async {
    final token = await SessionManager.accessToken;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

  static Future<http.Response> _withAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) request, {
    Map<String, String>? extraHeaders,
  }) async {
    final headers = await _buildHeaders(extraHeaders);
    final response = await request(headers);

    if (response.statusCode != 401 || headers.containsKey(_retryHeader)) {
      return response;
    }

    developer.log(
      'AuthHttpClient: 401 received, attempting refresh',
      name: 'AuthHttpClient',
    );

    final refreshed = await SessionManager.tryRefresh();
    if (!refreshed) {
      developer.log(
        'AuthHttpClient: refresh failed, session expired',
        name: 'AuthHttpClient',
      );
      return response;
    }

    developer.log(
      'AuthHttpClient: refresh succeeded, retrying request',
      name: 'AuthHttpClient',
    );

    final retryHeaders = await _buildHeaders(extraHeaders);
    retryHeaders[_retryHeader] = '1';
    return request(retryHeaders);
  }
}
