import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

const storage = FlutterSecureStorage();

class ApiService {
  static const String _baseUrl = 'http://192.168.0.18:3000';

  // ===========================
  // USERS / AUTH
  // ===========================

  static Future<String> register(
    String name,
    String surname,
    String email,
    String password,
    String dni,
    String birthDate,
  ) async {
    final userAgent = 'Flutter-Mobile-App/1.0';
    final ip = '192.168.0.69';
    final deviceId = 'flutter-mobile-app';

    final response = await http.post(
      Uri.parse('$_baseUrl/users/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'surname': surname,
        'email': email,
        'password': password,
        'dni': dni,
        'birthDate': birthDate,
        'userAgent': userAgent,
        'ip': ip,
        'deviceId': deviceId,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      String? userId;

      final tokenData = data['token'] as Map<String, dynamic>?;
      userId = tokenData?['id']?.toString();

      await storage.write(key: 'temp_email', value: email);
      await storage.write(key: 'temp_password', value: password);

      if (userId != null) {
        await storage.write(key: 'user_id', value: userId);
      } else {
        throw Exception('Error: userId no encontrado en la respuesta.');
      }
      return userId;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Error de registro desconocido';
      throw Exception(message);
    }
  }

  static Future<void> completeRegistration(
    String userId,
    String role, {
    String? licenceNumber,
    int? experienceYears,
    int? carId,
  }) async {
    if (role == 'Instructor') {
      final data = {
        'userId': int.parse(userId),
        'licenseNumber': licenceNumber,
        'experienceYears': experienceYears,
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/instructors/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message =
            errorData?['message'] ?? 'Error al registrar instructor';
        throw Exception(message);
      }
    } else {
      // ✅ Registrar estudiante usando nueva ruta PATCH /users/:id/role
      //    - Backend normaliza "Alumno" -> "STUDENT"
      //    - Respuesta esperada: 200 OK con usuario sin password
      final token = await storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json; charset=UTF-8',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$userId/role'),
        headers: headers,
        body: jsonEncode({'role': role}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 'Error al registrar estudiante';
        throw Exception(message);
      }
    }
  }

  static Future<void> registerAsStudent(String userId) async {
    await completeRegistration(userId, 'Alumno');
  }

  static Future<List<dynamic>> getCars() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/cars'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error al obtener la lista de autos');
    }
  }

  static Future<List<dynamic>> getInstructors() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/instructors'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Error al obtener instructores';
      throw Exception(message);
    }
  }

  // ✅ Actualizar perfil usando PUT /users/:id
  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final url = '$_baseUrl/users/$userId';
    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Error al actualizar el perfil';
      throw Exception(message);
    }
  }

  static Future<Map<String, dynamic>> reserveClass(String instructorId, Map<String, dynamic> reservationData) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    // 1) Obtener userId del storage o decodificar desde el JWT como fallback
    String? userId = await storage.read(key: 'user_id');
    if (userId == null || userId.isEmpty) {
      try {
        if (token.contains('.')) {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final payloadData = jsonDecode(decoded) as Map<String, dynamic>;
            userId = payloadData['id']?.toString() ??
                payloadData['userId']?.toString() ??
                payloadData['sub']?.toString();
          }
        }
      } catch (_) {
        // noop: fallback podría fallar
      }
    }

    if (userId == null || userId.isEmpty) {
      throw Exception('Sesión inválida. Inicia sesión nuevamente.');
    }

    // Upsert de Student previo a la reserva (idempotente)
    try {
      await http.patch(
        Uri.parse('$_baseUrl/users/$userId/role'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'role': 'Alumno'}),
      );
    } catch (_) {
      // ignorar errores de upsert preventivo
    }
    // Helper para reservar
    Future<http.Response> doReserve() {
      // Normalizar hora a HH:mm:ss si viene en HH:mm
      final String rawTime = reservationData['time']?.toString() ?? '';
      final String timeStr = RegExp(r'^\d{2}:\d{2}$').hasMatch(rawTime) ? '$rawTime:00' : rawTime;

      final payload = {
        'instructorId': int.parse(instructorId),
        'studentId': int.parse(userId!), // requerido por backend
        'date': reservationData['date'],
        'time': timeStr,
        'duration': 60,
        'status': 'scheduled', // valor permitido por el backend
      };

      return http.post(
        Uri.parse('$_baseUrl/classes'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
    }

    http.Response response = await doReserve();
    developer.log('reserveClass first attempt status: ${response.statusCode}, body: ${response.body}', name: 'ApiService');

    // 2) Si el backend indica que el estudiante no existe, forzar upsert del Student (PATCH role) y reintentar una vez
    if (response.statusCode >= 400) {
      try {
        String extractErrorText(String body) {
          try {
            final parsed = jsonDecode(body);
            if (parsed is Map<String, dynamic>) {
              final parts = <String>[];
              void collect(dynamic v) {
                if (v == null) return;
                if (v is String) parts.add(v);
                if (v is Map) {
                  for (final e in v.entries) {
                    collect(e.value);
                  }
                }
                if (v is List) {
                  for (final item in v) {
                    collect(item);
                  }
                }
              }

              // Campos típicos
              collect(parsed['message']);
              collect(parsed['error']);
              collect(parsed['detail']);
              collect(parsed['details']);
              collect(parsed['errors']);
              collect(parsed['code']);
              // Todo el objeto por si el mensaje está anidado
              collect(parsed);
              return parts.join(' | ');
            }
            return body;
          } catch (_) {
            return body;
          }
        }

        final raw = response.body;
        final errText = extractErrorText(raw).toLowerCase();

        final isStudentMissing =
            (errText.contains('estudiante') && (errText.contains('no existe') || errText.contains('no encontrado') || errText.contains('inexist'))) ||
            errText.contains('student not found') ||
            errText.contains('student does not exist') ||
            errText.contains('student not exist') ||
            errText.contains('student_missing') ||
            (errText.contains('student') && (errText.contains('exist') || (errText.contains('not') && errText.contains('found'))));

        if (isStudentMissing) {
          // Asegurar Student con PATCH role (backend hace upsert al poner STUDENT/"Alumno")
          await http.patch(
            Uri.parse('$_baseUrl/users/$userId/role'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'role': 'Alumno'}), // backend normaliza -> STUDENT
          );

          // Pequeño delay por consistencia eventual y reintentar una vez
          await Future.delayed(const Duration(milliseconds: 500));
          response = await doReserve();
          developer.log('reserveClass retry status: ${response.statusCode}, body: ${response.body}', name: 'ApiService');

          // Si aún falla por estudiante inexistente, intento final sin studentId (que lo infiera el backend)
          if (response.statusCode >= 400) {
            final retryRaw = response.body;
            final retryErr = extractErrorText(retryRaw).toLowerCase();
            final stillMissing =
                (retryErr.contains('estudiante') && (retryErr.contains('no existe') || retryErr.contains('no encontrado') || retryErr.contains('inexist'))) ||
                retryErr.contains('student not found') ||
                retryErr.contains('student does not exist') ||
                retryErr.contains('student not exist') ||
                retryErr.contains('student_missing') ||
                (retryErr.contains('student') && (retryErr.contains('exist') || (retryErr.contains('not') && retryErr.contains('found'))));

            if (stillMissing) {
              response = await doReserve();
              developer.log('reserveClass final fallback (no studentId) status: ${response.statusCode}, body: ${response.body}', name: 'ApiService');
            }
          }
        }
      } catch (_) {
        // Si algo falla en el intento de recuperación, se maneja abajo
      }
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Error al reservar la clase';
      developer.log('reserveClass final failure status: ${response.statusCode}, body: ${response.body}', name: 'ApiService');
      throw Exception('$message (HTTP ${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final userAgent = 'Flutter-Mobile-App/1.0';
    final ip = '192.168.1.1';

    final response = await http.post(
      Uri.parse('$_baseUrl/users/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'User-Agent': userAgent,
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'password': password,
        'userAgent': userAgent,
        'ip': ip,
        'deviceId': 'flutter-mobile-app',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      developer.log('Login response: $data', name: 'ApiService');

      String? accessToken;
      String? userId;
      String? refreshToken;
      Map<String, dynamic>? sessionData;

      // Try different response formats
      if (data['token'] is Map<String, dynamic>) {
        final tokenData = data['token'] as Map<String, dynamic>;
        userId = tokenData['id']?.toString() ?? tokenData['userId']?.toString();
        accessToken = tokenData['token']?.toString() ?? tokenData['accessToken']?.toString() ?? data['accessToken'] as String?;
        refreshToken = tokenData['refreshToken']?.toString() ?? data['refreshToken'] as String?;
      } else if (data['data'] is Map<String, dynamic>) {
        // Handle nested data structure
        final nestedData = data['data'] as Map<String, dynamic>;
        accessToken = nestedData['token']?.toString() ?? nestedData['accessToken']?.toString() ?? data['accessToken'] as String?;
        refreshToken = nestedData['refreshToken']?.toString() ?? data['refreshToken'] as String?;
        userId = nestedData['userId']?.toString() ?? nestedData['id']?.toString() ?? nestedData['user']?['id']?.toString();
      } else {
        // Direct response format
        accessToken = data['accessToken'] as String? ?? data['token'] as String?;
        refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>? ?? {};
        userId = user['id']?.toString() ?? data['userId']?.toString() ?? data['id']?.toString();

        // Try to extract from JWT if available
        if (userId == null && accessToken != null && accessToken.contains('.')) {
          try {
            final parts = accessToken.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalized = base64Url.normalize(payload);
              final decoded = utf8.decode(base64Url.decode(normalized));
              final payloadData = jsonDecode(decoded) as Map<String, dynamic>;
              userId = payloadData['id']?.toString() ?? payloadData['userId']?.toString() ?? payloadData['sub']?.toString();
            }
          } catch (e) {
            developer.log('Error parsing JWT: $e', name: 'ApiService');
          }
        }
      }

      // Handle session data
      if (data['session'] is Map<String, dynamic>) {
        sessionData = data['session'] as Map<String, dynamic>;
      } else if (data['data']?['session'] is Map<String, dynamic>) {
        sessionData = data['data']['session'] as Map<String, dynamic>;
      }

      developer.log('Parsed - Token: ${accessToken != null ? "present" : "null"}, UserId: ${userId != null ? "present" : "null"}', name: 'ApiService');

      if (accessToken != null && userId != null) {
        await storage.write(key: 'auth_token', value: accessToken);
        await storage.write(key: 'user_id', value: userId);
        await storage.write(key: 'user_email', value: email);
        if (refreshToken != null) {
          await storage.write(key: 'refresh_token', value: refreshToken);
        }
        if (sessionData != null) {
          await storage.write(key: 'session_data', value: jsonEncode(sessionData));
        }
        return {
          'token': accessToken,
          'userId': userId,
          'refreshToken': refreshToken,
          'session': sessionData
        };
      } else {
        developer.log('Login failed - Missing data. Response keys: ${data.keys.toList()}', name: 'ApiService');
        throw Exception('Error: token o userId no encontrado en la respuesta. Respuesta: ${data.keys.join(", ")}');
      }
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Credenciales incorrectas';
      throw Exception(message);
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final url = '$_baseUrl/users/$userId';
    final response = await http.get(
      Uri.parse(url),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error al obtener el perfil del usuario');
    }
  }

  static Future<void> logout() async {
    final sessionId = await storage.read(key: 'session_id');
    final token = await storage.read(key: 'auth_token');

    if (sessionId != null && token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/sessions/revoke'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'sessionId': sessionId}),
        );
      } catch (_) {
        // noop
      }
    }

    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'session_id');
    await storage.delete(key: 'session_created_at');
    await storage.delete(key: 'session_expires_at');
    await storage.delete(key: 'session_data');
    await storage.delete(key: 'temp_email');
    await storage.delete(key: 'temp_password');
    await storage.delete(key: 'pending_role');
    await storage.delete(key: 'pending_licenseNumber');
    await storage.delete(key: 'pending_experienceYears');
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      throw Exception('No hay refresh token disponible');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/refresh'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newAccessToken != null) {
        await storage.write(key: 'auth_token', value: newAccessToken);
        if (newRefreshToken != null) {
          await storage.write(key: 'refresh_token', value: newRefreshToken);
        }
        return {'token': newAccessToken, 'refreshToken': newRefreshToken};
      } else {
        throw Exception('Error: nuevo token no encontrado en respuesta');
      }
    } else {
      await logout();
      throw Exception('Sesión expirada, por favor inicia sesión nuevamente');
    }
  }

  static Future<bool> isSessionValid() async {
    try {
      final expiresAt = await storage.read(key: 'session_expires_at');
      if (expiresAt == null) return false;
      final expiryDate = DateTime.parse(expiresAt);
      final now = DateTime.now();
      return now.isBefore(expiryDate);
    } catch (_) {
      return false;
    }
  }

    // ===========================
  // MERCADO PAGO – FRONTEND
  // ===========================

  static Future<Map<String, dynamic>> mpCreatePreference({
    required int drivingClassId,
    required int amount,
    required String description,
    String? payerEmail,
    String? successUrl,
    String? failureUrl,
    String? pendingUrl,
  }) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final body = {
      'amount': amount,
      'drivingClassId': drivingClassId,
      'description': description,
      if (payerEmail != null) 'payerEmail': payerEmail,
      if (successUrl != null) 'successUrl': successUrl,
      if (failureUrl != null) 'failureUrl': failureUrl,
      if (pendingUrl != null) 'pendingUrl': pendingUrl,
    };

    final res = await http.post(
      Uri.parse('$_baseUrl/payments/mercadopago/preference'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error al crear preferencia');
    }
  }

  static Future<Map<String, dynamic>> mpGetPaymentStatus(String paymentIdOrExternalRef) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final res = await http.get(
      Uri.parse('$_baseUrl/payments/mercadopago/status/$paymentIdOrExternalRef'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(res.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error al consultar estado');
    }
  }
}