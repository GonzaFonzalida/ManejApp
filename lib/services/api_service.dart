import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;
import 'config_service.dart';

const storage = FlutterSecureStorage();

class ApiService {
  static String get _baseUrl => '${ConfigService.baseUrl}/api/v1';



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
    developer.log('=== COMPLETE REGISTRATION ===', name: 'ApiService');
    developer.log('userId: $userId, role: $role', name: 'ApiService');
    
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
    }
    // Para estudiantes no se hace nada, el backend los crea automáticamente al reservar
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

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/instructors'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      developer.log('getInstructors - Status: ${response.statusCode}', name: 'ApiService');
      developer.log('getInstructors - Body: ${response.body}', name: 'ApiService');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 'Error al obtener instructores';
        throw Exception(message);
      }
    } catch (e) {
      developer.log('Error en getInstructors: $e', name: 'ApiService');
      throw Exception('No se pudo conectar al servidor en $_baseUrl');
    }
  }

  // ✅ Actualizar perfil de instructor usando PUT /instructors/:id
  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    developer.log('updateProfile - userId: $userId, data: $data', name: 'ApiService');

    // Obtener el instructor ID basado en el userId
    final instructors = await getInstructors();
    final instructor = instructors.firstWhere(
      (inst) => inst['userId'].toString() == userId,
      orElse: () => throw Exception('Instructor no encontrado para userId: $userId'),
    );
    
    final instructorId = instructor['id'].toString();
    final url = '$_baseUrl/instructors/$instructorId';
    
    developer.log('Actualizando instructor - URL: $url', name: 'ApiService');
    developer.log('Datos: ${jsonEncode(data)}', name: 'ApiService');
    
    final response = await http.put(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    
    developer.log('Response status: ${response.statusCode}', name: 'ApiService');
    developer.log('Response body: ${response.body}', name: 'ApiService');

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
          // Reintentar la reserva
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

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'User-Agent': userAgent,
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'password': password,
        'userAgent': userAgent,
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
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al obtener el perfil del usuario');
      }
    } catch (e) {
      developer.log('Error en getUserProfile: $e', name: 'ApiService');
      throw Exception('No se pudo conectar al servidor. Verifica tu conexión.');
    }
  }

  static Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> data) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData['user'] as Map<String, dynamic>? ?? responseData;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error al actualizar usuario');
    }
  }

  static Future<Map<String, dynamic>> uploadProfileImage(String userId, File imageFile) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    developer.log('=== UPLOAD IMAGE ===', name: 'ApiService');
    developer.log('URL: $_baseUrl/users/$userId/upload-profile-image', name: 'ApiService');
    developer.log('File: ${imageFile.path}', name: 'ApiService');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/users/$userId/upload-profile-image'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('profileImage', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    developer.log('Response status: ${response.statusCode}', name: 'ApiService');
    developer.log('Response body: ${response.body}', name: 'ApiService');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error al subir imagen (${response.statusCode})');
    }
  }

  static Future<List<Map<String, String>>> searchLocations(String query) async {
    if (query.length < 3) return [];
    
    final url = 'https://nominatim.openstreetmap.org/search?q=$query,Argentina&format=json&limit=5&addressdetails=1';
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'ManejApp/1.0'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> results = jsonDecode(response.body);
      return results.map((r) {
        final address = r['address'] as Map<String, dynamic>?;
        final city = address?['city'] ?? address?['town'] ?? address?['village'] ?? '';
        final state = address?['state'] ?? '';
        return {
          'display': '$city, $state',
          'lat': r['lat'] as String,
          'lon': r['lon'] as String,
        };
      }).toList();
    }
    return [];
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await storage.read(key: 'auth_token');
    final userId = await storage.read(key: 'user_id');
    if (token == null || userId == null) {
      throw Exception('No hay sesión activa');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error al cambiar contraseña');
    }
  }

  static Future<void> changeEmail(String newEmail, String password) async {
    final token = await storage.read(key: 'auth_token');
    final userId = await storage.read(key: 'user_id');
    if (token == null || userId == null) {
      throw Exception('No hay sesión activa');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'email': newEmail,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error al cambiar email');
    }
    
    await storage.write(key: 'user_email', value: newEmail);
  }

  static Future<void> logout() async {
    final token = await storage.read(key: 'auth_token');

    if (token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
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
  // AUTH EXTENDED
  // ===========================

  static Future<Map<String, dynamic>> getMe() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo información del usuario');
    }
  }

  static Future<List<dynamic>> getSessions() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/auth/sessions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo sesiones');
    }
  }

  static Future<void> revokeSession(String sessionId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/revoke/$sessionId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error revocando sesión');
    }
  }

  static Future<void> revokeAllSessions() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.post(
      Uri.parse('$_baseUrl/auth/revoke-all'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error revocando todas las sesiones');
    }
  }

  // ===========================
  // USERS EXTENDED
  // ===========================

  static Future<List<dynamic>> getUsersByRole(String role) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/users/role/$role'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo usuarios por rol');
    }
  }

  // ===========================
  // INSTRUCTORS EXTENDED
  // ===========================

  static Future<void> updateInstructor(String instructorId, Map<String, dynamic> data) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final url = '$_baseUrl/instructors/$instructorId';
    developer.log('=== UPDATE INSTRUCTOR ===', name: 'ApiService');
    developer.log('URL: $url', name: 'ApiService');
    developer.log('Data: ${jsonEncode(data)}', name: 'ApiService');

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    developer.log('Response status: ${response.statusCode}', name: 'ApiService');
    developer.log('Response body: ${response.body}', name: 'ApiService');

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error actualizando instructor');
    }
  }

  // ===========================
  // CARS MANAGEMENT
  // ===========================

  static Future<Map<String, dynamic>> createCar(Map<String, dynamic> carData) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.post(
      Uri.parse('$_baseUrl/cars'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(carData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error creando auto');
    }
  }

  static Future<Map<String, dynamic>> getCar(String carId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/cars/$carId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo auto');
    }
  }

  static Future<void> updateCar(String carId, Map<String, dynamic> carData) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.put(
      Uri.parse('$_baseUrl/cars/$carId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(carData),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error actualizando auto');
    }
  }

  static Future<void> deleteCar(String carId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.delete(
      Uri.parse('$_baseUrl/cars/$carId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error eliminando auto');
    }
  }

  // ===========================
  // DRIVING CLASSES
  // ===========================

  static Future<List<dynamic>> getDrivingClasses() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/classes'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo clases');
    }
  }

  static Future<List<dynamic>> getMyDrivingClasses() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/classes/my-classes'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo mis clases');
    }
  }

  static Future<Map<String, dynamic>> getDrivingClass(String classId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/classes/$classId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo clase');
    }
  }

  static Future<Map<String, dynamic>> createDrivingClass(Map<String, dynamic> classData) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.post(
      Uri.parse('$_baseUrl/classes'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(classData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error creando clase');
    }
  }

  static Future<void> updateDrivingClass(String classId, Map<String, dynamic> classData) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.put(
      Uri.parse('$_baseUrl/classes/$classId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(classData),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error actualizando clase');
    }
  }

  static Future<void> cancelDrivingClass(String classId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.patch(
      Uri.parse('$_baseUrl/classes/$classId/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error cancelando clase');
    }
  }

  static Future<void> deleteDrivingClass(String classId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.delete(
      Uri.parse('$_baseUrl/classes/$classId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error eliminando clase');
    }
  }

  // ===========================
  // PAYMENTS EXTENDED
  // ===========================

  static Future<List<dynamic>> getPayments() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/payments'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo pagos');
    }
  }

  static Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/payments/$paymentId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo pago');
    }
  }

  static Future<List<dynamic>> getPaymentsByClass(String classId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/payments/driving-class/$classId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo pagos de la clase');
    }
  }

  static Future<void> updatePaymentStatus(String paymentId, String status) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.put(
      Uri.parse('$_baseUrl/payments/$paymentId/status'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error actualizando estado del pago');
    }
  }

  // ===========================
  // SCHEDULE MANAGEMENT
  // ===========================

  static Future<Map<String, dynamic>> createScheduleSlot(Map<String, dynamic> slotData) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.post(
      Uri.parse('$_baseUrl/schedule/slots'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(slotData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error creando horario');
    }
  }

  static Future<Map<String, dynamic>> getScheduleSlot(String slotId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/schedule/$slotId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo horario');
    }
  }

  static Future<List<dynamic>> getInstructorSchedule(String instructorId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/schedule/instructor/$instructorId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo horarios del instructor');
    }
  }

  static Future<Map<String, dynamic>> reserveScheduleSlot(String slotId) async {
    String? token = await storage.read(key: 'auth_token');
    
    if (token == null || token.isEmpty) {
      developer.log('Token not found, trying to refresh...', name: 'ApiService');
      try {
        final refreshResult = await refreshToken();
        token = refreshResult['token'];
      } catch (e) {
        throw Exception('Sesión expirada. Inicia sesión nuevamente.');
      }
    }

    if (slotId.isEmpty) {
      throw Exception('ID del slot no puede estar vacío');
    }

    developer.log('Reservando slot - slotId: "$slotId"', name: 'ApiService');
    developer.log('Token exists: ${token!.isNotEmpty}', name: 'ApiService');
    
    final url = '$_baseUrl/schedule/reserve/$slotId';
    developer.log('URL: $url', name: 'ApiService');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}),
    );

    developer.log('Response status: ${response.statusCode}', name: 'ApiService');
    developer.log('Response body: ${response.body}', name: 'ApiService');

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      if (errorData is List) {
        final firstError = errorData.isNotEmpty ? errorData[0] : {};
        throw Exception(firstError['message'] ?? 'Error reservando horario');
      } else if (errorData is Map<String, dynamic>) {
        throw Exception(errorData['message'] ?? 'Error reservando horario');
      } else {
        throw Exception('Error reservando horario');
      }
    }
  }

  static Future<void> cancelScheduleSlot(String slotId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.post(
      Uri.parse('$_baseUrl/schedule/cancel/$slotId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error cancelando reserva');
    }
  }

  static Future<void> deleteScheduleSlot(String slotId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.delete(
      Uri.parse('$_baseUrl/schedule/$slotId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error eliminando horario');
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

  // ===========================
  // ADMIN
  // ===========================

  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/admin/dashboard/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo estadísticas');
    }
  }

  static Future<Map<String, dynamic>> getSystemHealth() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/admin/system/health'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo salud del sistema');
    }
  }

  static Future<void> manageUser(String userId, {required bool isActive}) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.patch(
      Uri.parse('$_baseUrl/admin/users/$userId/manage'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'action': isActive ? 'activate' : 'deactivate'}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error gestionando usuario');
    }
  }

  // ===========================
  // LOGS
  // ===========================

  static Future<Map<String, dynamic>> getLogs({String? level, int limit = 100, int offset = 0}) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final queryParams = {
      'limit': limit.toString(),
      'offset': offset.toString(),
      if (level != null) 'level': level,
    };

    final uri = Uri.parse('$_baseUrl/logs').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo logs');
    }
  }

  static Future<List<dynamic>> getLogStats() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/logs/stats'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo estadísticas de logs');
    }
  }
}