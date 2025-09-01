import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

class ApiService {
  static const String _baseUrl = 'http://192.168.0.63:3000';

  static Future<String> register(String name, String surname, String email, String password, String dni, String birthDate) async {
    final userAgent = 'Flutter-Mobile-App/1.0';
    final ip = '192.168.0.63'; // In a real app, you'd get the actual IP
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

    print('Respuesta del servidor (register raw): ${response.statusCode} - ${response.body}'); // Depuración

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      String? userId;

      // Extraer el userId del objeto dentro de 'token'
      final tokenData = data['token'] as Map<String, dynamic>?;
      userId = tokenData?['id']?.toString();

      // Guardar las credenciales temporales para el login
      await storage.write(key: 'temp_email', value: email);
      await storage.write(key: 'temp_password', value: password);

      if (userId != null) {
        await storage.write(key: 'user_id', value: userId);
      } else {
        throw Exception('Error: userId no encontrado en la respuesta.');
      }

      return userId ?? ''; // Devuelve el userId o cadena vacía si falla
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Error de registro desconocido';
      throw Exception(message);
    }
  }

  static Future<void> completeRegistration(String userId, String role, {String? licenceNumber, int? experienceYears, int? carId}) async {
    if (role == 'Instructor') {
      final data = {
        'userId': int.parse(userId),
        'licenseNumber': licenceNumber,
        'experienceYears': experienceYears,
        // Omitimos carId por ahora y coordinaremos con el backend
      };
      final response = await http.post(
        Uri.parse('$_baseUrl/instructors/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      print('Datos enviados (completeRegistration): $data'); // Depuración
      print('Respuesta del servidor (completeRegistration raw): ${response.statusCode} - ${response.body}'); // Depuración

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 'Error al registrar instructor';
        throw Exception(message);
      }
    } else {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({'role': role}),
      );

      print('Respuesta del servidor (completeRegistration raw): ${response.statusCode} - ${response.body}'); // Depuración

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 'Error al actualizar usuario';
        throw Exception(message);
      }
    }
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
      throw Exception('Error al obtener la lista de instructores');
    }
  }

  static Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final url = userId.startsWith('I') ? '$_baseUrl/instructors/${userId.replaceFirst('I', '')}' : '$_baseUrl/users/$userId';
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

  static Future<void> reserveClass(String instructorId, Map<String, dynamic> reservationData) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final userId = await storage.read(key: 'user_id');
    if (userId == null) {
      throw Exception('No hay userId disponible.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/classes'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({...reservationData, 'instructorId': instructorId, 'userId': userId}),
    );

    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Error al reservar la clase';
      throw Exception(message);
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    // Get device information for session
    final userAgent = 'Flutter-Mobile-App/1.0';
    final ip = '192.168.1.1'; // In a real app, you'd get the actual IP

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
        'ip': ip,
        'deviceId': 'flutter-mobile-app',
      }),
    );

    print('Respuesta del servidor (login raw): ${response.statusCode} - ${response.body}'); // Depuración

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      print('Parsed data: $data'); // Added debug logging
      String? accessToken;
      String? userId;
      String? refreshToken;
      Map<String, dynamic>? sessionData;

      if (data['token'] is Map<String, dynamic>) {
        final tokenData = data['token'] as Map<String, dynamic>;
        userId = tokenData['id']?.toString();
        accessToken = tokenData['token']?.toString() ?? data['accessToken'] as String?;
        refreshToken = tokenData['refreshToken']?.toString();
      } else {
        accessToken = data['accessToken'] as String? ?? data['token'] as String?;
        refreshToken = data['refreshToken'] as String?;
        final user = data['user'] as Map<String, dynamic>? ?? {};
        userId = user['id']?.toString() ?? data['userId']?.toString() ?? data['id']?.toString();

        // If userId is still null and accessToken is a JWT, decode it to extract userId
        if (userId == null && accessToken != null && accessToken.contains('.')) {
          try {
            final parts = accessToken.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalized = base64Url.normalize(payload);
              final decoded = utf8.decode(base64Url.decode(normalized));
              final payloadData = jsonDecode(decoded) as Map<String, dynamic>;
              userId = payloadData['id']?.toString();
              print('Decoded userId from JWT: $userId');
            }
          } catch (e) {
            print('Error decoding JWT: $e');
          }
        }
      }

      // Extract session data if provided by backend
      if (data['session'] is Map<String, dynamic>) {
        sessionData = data['session'] as Map<String, dynamic>;
        print('Session data received: $sessionData');
      }

      print('Extracted accessToken: $accessToken, userId: $userId, refreshToken: $refreshToken'); // Added debug logging

      if (accessToken != null && userId != null) {
        await storage.write(key: 'auth_token', value: accessToken);
        await storage.write(key: 'user_id', value: userId);
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
        throw Exception('Error: token ($accessToken) o userId ($userId) no encontrado en la respuesta. Respuesta completa: $data');
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

    final url = userId.startsWith('I') ? '$_baseUrl/instructors/${userId.replaceFirst('I', '')}' : '$_baseUrl/users/$userId';
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
        // Revoke session on backend
        await http.post(
          Uri.parse('$_baseUrl/sessions/revoke'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'sessionId': sessionId}),
        );
      } catch (e) {
        print('Error revoking session: $e');
        // Continue with local cleanup even if backend call fails
      }
    }

    // Clear all stored data
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
      // If refresh fails, logout user
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
    } catch (e) {
      print('Error checking session: $e');
      return false;
    }
  }
}