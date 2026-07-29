import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manejapp/services/auth_http_client.dart';
import 'package:manejapp/services/config_service.dart';
import 'package:manejapp/services/session_manager.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:test/test.dart';

void main() {
  group('SessionManager', () {
    test('tryRefresh sin refresh_token devuelve false', () async {
      FlutterSecureStorage.setMockInitialValues({});
      expect(await SessionManager.tryRefresh(), isFalse);
    });

    test('saveSession persiste tokens y userId', () async {
      FlutterSecureStorage.setMockInitialValues({});
      await SessionManager.saveSession(
        accessToken: 'acc',
        refreshToken: 'ref',
        userId: '99',
        email: 't@test.com',
      );
      expect(await SessionManager.accessToken, 'acc');
      expect(await SessionManager.refreshToken, 'ref');
      expect(await SessionManager.userId, '99');
      expect(await SessionManager.hasSession, isTrue);
    });

    test('tryRefresh con mock HTTP actualiza tokens', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      ConfigService.setIntegrationTestBaseUrl('http://127.0.0.1:$port');
      addTearDown(() async {
        ConfigService.setIntegrationTestBaseUrl(null);
        await server.close(force: true);
      });

      server.listen((HttpRequest req) async {
        if (req.uri.path == '/api/v1/auth/refresh' && req.method == 'POST') {
          final body = jsonEncode({
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'session': {'id': 's1'},
          });
          req.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(body);
        } else {
          req.response.statusCode = HttpStatus.notFound;
        }
        await req.response.close();
      });

      FlutterSecureStorage.setMockInitialValues({
        'refresh_token': 'old-refresh',
      });

      expect(await SessionManager.tryRefresh(), isTrue);
      expect(await SessionManager.accessToken, 'new-access');
      expect(await SessionManager.refreshToken, 'new-refresh');
    });

    test('clearSession borra claves locales (logout sin servidor)', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'a',
        'refresh_token': 'r',
        'user_id': '1',
        'user_email': 'u@test.com',
      });
      ConfigService.setIntegrationTestBaseUrl('http://127.0.0.1:9');
      addTearDown(() => ConfigService.setIntegrationTestBaseUrl(null));
      await SessionManager.clearSession();
      expect(await SessionManager.accessToken, isNull);
      expect(await SessionManager.refreshToken, isNull);
      expect(await SessionManager.userId, isNull);
      expect(await SessionManager.userEmail, isNull);
    });

    test(
        'warmUpSession mantiene sesión con access token aunque no haya refresh',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'access-only',
        'user_id': '1',
      });
      expect(await SessionManager.warmUpSession(), isTrue);
    });

    test('warmUpSession falla sin tokens', () async {
      FlutterSecureStorage.setMockInitialValues({});
      expect(await SessionManager.warmUpSession(), isFalse);
    });
  });

  group('ApiService.register session', () {
    test('con accessToken sin refresh completa sesión vía login', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      ConfigService.setIntegrationTestBaseUrl('http://127.0.0.1:$port');
      addTearDown(() async {
        ConfigService.setIntegrationTestBaseUrl(null);
        await server.close(force: true);
      });

      server.listen((HttpRequest req) async {
        final path = req.uri.path;
        if (path == '/api/v1/users/register' && req.method == 'POST') {
          req.response
            ..statusCode = HttpStatus.created
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'token': {'id': 42, 'email': 'new@test.com'},
              'accessToken': 'register-access',
            }));
        } else if (path == '/api/v1/auth/login' && req.method == 'POST') {
          req.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'accessToken': 'login-access',
              'refreshToken': 'login-refresh',
              'user': {'id': 42, 'email': 'new@test.com'},
              'session': {'id': 's1'},
            }));
        } else {
          req.response.statusCode = HttpStatus.notFound;
        }
        await req.response.close();
      });

      FlutterSecureStorage.setMockInitialValues({});

      final reg = await ApiService.register(
        'Ana',
        'Test',
        'new@test.com',
        'password123',
        '12345678',
        '2000-01-01',
      );

      expect(reg.userId, '42');
      expect(await SessionManager.accessToken, 'login-access');
      expect(await SessionManager.refreshToken, 'login-refresh');
      expect(await SessionManager.userId, '42');
      expect(await SessionManager.hasSession, isTrue);
    });

    test('sin accessToken no persiste sesión auth', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      ConfigService.setIntegrationTestBaseUrl('http://127.0.0.1:$port');
      addTearDown(() async {
        ConfigService.setIntegrationTestBaseUrl(null);
        await server.close(force: true);
      });

      server.listen((HttpRequest req) async {
        if (req.uri.path == '/api/v1/users/register' && req.method == 'POST') {
          req.response
            ..statusCode = HttpStatus.created
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'token': {'id': 7, 'email': 'pending@test.com'},
              'requiresEmailVerification': true,
              'message': 'Revisá tu correo',
            }));
        } else {
          req.response.statusCode = HttpStatus.notFound;
        }
        await req.response.close();
      });

      FlutterSecureStorage.setMockInitialValues({});

      final reg = await ApiService.register(
        'Bob',
        'Pending',
        'pending@test.com',
        'password123',
        '87654321',
        '1999-05-05',
      );

      expect(reg.userId, '7');
      expect(await SessionManager.accessToken, isNull);
      expect(await SessionManager.refreshToken, isNull);
      expect(await SessionManager.hasSession, isFalse);
      expect(await SessionManager.userId, '7');
    });
  });

  group('AuthHttpClient', () {
    test('tras 401 hace refresh y reintenta GET', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      ConfigService.setIntegrationTestBaseUrl('http://127.0.0.1:$port');
      addTearDown(() async {
        ConfigService.setIntegrationTestBaseUrl(null);
        await server.close(force: true);
      });

      var getCount = 0;
      server.listen((HttpRequest req) async {
        final path = req.uri.path;
        if (path == '/api/v1/auth/refresh' && req.method == 'POST') {
          req.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'accessToken': 'fresh',
              'refreshToken': 'ref2',
            }));
        } else if (path == '/api/v1/ping' && req.method == 'GET') {
          getCount++;
          final auth = req.headers.value(HttpHeaders.authorizationHeader);
          if (getCount == 1) {
            req.response.statusCode = HttpStatus.unauthorized;
          } else if (auth != null && auth.contains('fresh')) {
            req.response
              ..statusCode = HttpStatus.ok
              ..write('ok');
          } else {
            req.response.statusCode = HttpStatus.unauthorized;
          }
        } else {
          req.response.statusCode = HttpStatus.notFound;
        }
        await req.response.close();
      });

      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'stale',
        'refresh_token': 'valid-refresh',
      });

      final res = await AuthHttpClient.get(
          Uri.parse('http://127.0.0.1:$port/api/v1/ping'));
      expect(res.statusCode, 200);
      expect(res.body, 'ok');
      expect(getCount, 2);
    });
  });
}
