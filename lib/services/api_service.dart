import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'config_service.dart';
import 'connectivity_service.dart';
import 'session_manager.dart';
import 'auth_http_client.dart';
import 'secure_storage.dart';
import 'biometric_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manejapp/models/payment_status_result.dart';

final storage = appSecureStorage;

/// Resultado de [ApiService.register]: [serverMessage] viene del API cuando falta verificación por email.
typedef RegisterResult = ({String userId, String? serverMessage});

class ApiService {
  static String get _baseUrl => '${ConfigService.baseUrl}/api/v1';
  static String get baseUrl => _baseUrl;
  static const Duration _locationSearchTimeout = Duration(seconds: 2);
  static const Duration _locationSearchCacheTtl = Duration(minutes: 3);
  static final Map<String, _LocationCacheEntry> _locationSearchCache = {};
  static final Map<String, Future<List<Map<String, String>>>>
      _locationSearchInFlight = {};

  // ===========================
  // USERS / AUTH
  // ===========================

  /// POST /users/register. No retry (evita doble 409). 409 = usuario ya existe → intenta login y devuelve userId.
  static Future<RegisterResult> register(
    String name,
    String surname,
    String email,
    String password,
    String dni,
    String birthDate, {
    String? phoneNumber,
    String? location,
  }) async {
    final userAgent = 'Flutter-Mobile-App/1.0';
    final deviceId = 'flutter-mobile-app';

    try {
      developer.log(
          'register: POST $_baseUrl/users/register (single attempt, no retry)',
          name: 'ApiService');
      final response = await http
          .post(
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
              if (phoneNumber != null && phoneNumber.isNotEmpty)
                'phoneNumber': phoneNumber,
              if (location != null && location.isNotEmpty) 'location': location,
            }),
          )
          .timeout(const Duration(seconds: 15));

      developer.log('register: status=${response.statusCode}',
          name: 'ApiService');

      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>?;
      } catch (_) {
        throw Exception(
            'Respuesta inválida del servidor. ¿Está el backend en $_baseUrl?');
      }

      if (response.statusCode == 201 && data != null) {
        String? userId;
        final tokenData = data['token'];
        if (tokenData is Map<String, dynamic>) {
          userId = tokenData['id']?.toString();
        }

        await storage.write(key: 'temp_email', value: email);
        await storage.write(key: 'temp_password', value: password);

        if (userId == null || userId.isEmpty) {
          throw Exception('Error: userId no encontrado en la respuesta.');
        }

        await storage.write(key: 'user_id', value: userId);

        await _establishSessionAfterRegister(
          email: email,
          password: password,
          userId: userId,
          registerData: data,
        );

        final serverMessage = data['message'] as String?;
        return (userId: userId, serverMessage: serverMessage);
      }

      if (response.statusCode == 409) {
        developer.log(
            'register: 409 Conflict - usuario ya existe, intentando login',
            name: 'ApiService');
        try {
          final loginResult = await login(email, password);
          final userId = loginResult['userId']?.toString();
          if (userId != null && userId.isNotEmpty) {
            await storage.write(key: 'temp_email', value: email);
            await storage.write(key: 'temp_password', value: password);
            return (userId: userId, serverMessage: null);
          }
        } catch (loginErr) {
          developer.log('register: login después de 409 falló: $loginErr',
              name: 'ApiService');
        }
        throw Exception(
            'Este usuario ya existe. Iniciá sesión con tu email y contraseña.');
      }

      final message = data?['message'] ??
          data?['error'] ??
          'Error de registro (${response.statusCode})';
      throw Exception(message);
    } on http.ClientException catch (e) {
      developer.log('ClientException en register: $e', name: 'ApiService');
      throw Exception(ConnectivityService.connectionErrorMessage);
    } on Exception catch (e) {
      if (e.toString().contains('connection') ||
          e.toString().contains('Connection') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(ConnectivityService.connectionErrorMessage);
      }
      rethrow;
    }
  }

  /// Same persistence path as [login] / Google / Apple.
  static Future<Map<String, dynamic>> _persistAuthResponse(
    Map<String, dynamic> data, {
    required String email,
  }) async {
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    final userId = user?['id']?.toString();
    final sessionData = data['session'] as Map<String, dynamic>?;

    if (accessToken == null || userId == null) {
      throw Exception('Error: token o userId no encontrado en la respuesta.');
    }

    await SessionManager.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      userId: userId,
      email: email,
      session: sessionData,
    );

    return {
      'token': accessToken,
      'userId': userId,
      'refreshToken': refreshToken,
      'session': sessionData,
      'user': user,
    };
  }

  /// POST /users/register returns accessToken only in some environments and never
  /// returns refresh/session today. Align with login by completing via /auth/login.
  static Future<void> _establishSessionAfterRegister({
    required String email,
    required String password,
    required String userId,
    required Map<String, dynamic> registerData,
  }) async {
    final accessToken = registerData['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) return;

    final refreshToken = registerData['refreshToken'] as String?;
    final sessionData = registerData['session'] as Map<String, dynamic>?;

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SessionManager.saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
        email: email,
        session: sessionData,
      );
      return;
    }

    try {
      await login(email, password);
    } catch (e) {
      developer.log(
        'register: login after accessToken failed, saving access-only session: $e',
        name: 'ApiService',
      );
      await SessionManager.saveSession(
        accessToken: accessToken,
        refreshToken: '',
        userId: userId,
        email: email,
        session: sessionData,
      );
    }
  }

  static Future<void> completeRegistration(
    String userId,
    String role, {
    int? experienceYears,
    int? carId,
    required String whatsappNumber,
  }) async {
    developer.log('=== COMPLETE REGISTRATION ===', name: 'ApiService');
    developer.log('userId: $userId, role: $role', name: 'ApiService');

    if (role.toUpperCase() == 'INSTRUCTOR') {
      if (experienceYears == null) {
        throw Exception('experienceYears: requerido');
      }

      final data = <String, dynamic>{
        'experienceYears': experienceYears,
        'whatsappNumber': whatsappNumber,
      };
      final response = await AuthHttpClient.post(
        Uri.parse('$_baseUrl/instructors/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 201) {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message =
            errorData?['message'] ?? 'Error al registrar instructor';
        throw Exception(message);
      }
    } else {
      await updateMyWhatsApp(whatsappNumber);
    }
    // La fila Student se crea durante el alta y también se asegura al reservar.
  }

  /// PATCH /users/me/whatsapp — guarda un número internacional normalizado.
  static Future<String> updateMyWhatsApp(String whatsappNumber) async {
    final response = await AuthHttpClient.patch(
      Uri.parse('$_baseUrl/users/me/whatsapp'),
      body: jsonEncode(<String, dynamic>{'whatsappNumber': whatsappNumber}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data']?['phoneNumber']?.toString() ?? whatsappNumber;
    }
    final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
    throw Exception(
      errorData?['message'] ??
          errorData?['error'] ??
          'No pudimos guardar tu WhatsApp',
    );
  }

  /// Completa una única vez la identidad real de cuentas creadas con Google/Apple.
  static Future<void> updateMyIdentity({
    required String dni,
    required String birthDate,
  }) async {
    final response = await AuthHttpClient.patch(
      Uri.parse('$_baseUrl/users/me/identity'),
      body: jsonEncode(<String, dynamic>{
        'dni': dni,
        'birthDate': birthDate,
      }),
    );
    if (response.statusCode == 200) return;
    final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
    throw Exception(
      errorData?['message'] ??
          errorData?['error'] ??
          'No pudimos validar tus datos personales',
    );
  }

  /// PATCH /users/student-profile — actualiza nivel de experiencia (1–5). Requiere rol STUDENT.
  static Future<void> patchStudentProfile(int experienceLevel) async {
    if (experienceLevel < 1 || experienceLevel > 5) {
      throw Exception('Nivel de experiencia inválido');
    }
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http
        .patch(
          Uri.parse('$_baseUrl/users/student-profile'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body:
              jsonEncode(<String, dynamic>{'experienceLevel': experienceLevel}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) return;

    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message']?.toString() ??
          errorData?['error']?.toString() ??
          'Error al guardar nivel de experiencia (${response.statusCode})';
      throw Exception(message);
    } catch (_) {
      throw Exception(
          'Error al guardar nivel de experiencia (${response.statusCode})');
    }
  }

  /// PUT /instructors/me (auth required, INSTRUCTOR only)
  static Future<Map<String, dynamic>> updateInstructorMe(
      Map<String, dynamic> data) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final url = Uri.parse('$_baseUrl/instructors/me');
    developer.log('updateInstructorMe - url=$url data=${jsonEncode(data)}',
        name: 'ApiService');

    final response = await http
        .put(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    Map<String, dynamic>? err;
    try {
      err = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {}

    if (response.statusCode == 422) {
      final missing = err?['missing'];
      final base = err?['message']?.toString() ?? 'Requisitos incompletos';
      if (missing is List && missing.isNotEmpty) {
        throw Exception('$base: ${missing.join(', ')}');
      }
      throw Exception(base);
    }

    throw Exception(err?['message'] ??
        'Error actualizando instructor (HTTP ${response.statusCode})');
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

  static Future<List<dynamic>> getInstructors({
    double? minPrice,
    double? maxPrice,
    String? transmission,
    bool? hasAvailability,
  }) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final queryParams = <String, String>{};
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (transmission != null) queryParams['transmission'] = transmission;
    if (hasAvailability == true) queryParams['hasAvailability'] = 'true';

    final uri = queryParams.isEmpty
        ? Uri.parse('$_baseUrl/instructors')
        : Uri.parse('$_baseUrl/instructors')
            .replace(queryParameters: queryParams);

    try {
      final response = await ConnectivityService.getWithRetry(
        uri,
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('getInstructors - Status: ${response.statusCode}',
          name: 'ApiService');
      developer.log('getInstructors - Body: ${response.body}',
          name: 'ApiService');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final message =
            errorData?['message'] ?? 'Error al obtener instructores';
        throw Exception(message);
      }
    } catch (e) {
      developer.log('Error en getInstructors: $e', name: 'ApiService');
      throw Exception('No se pudo conectar al servidor en $_baseUrl');
    }
  }

  // ✅ Actualizar perfil de instructor usando PUT /instructors/:id
  static Future<void> updateProfile(
      String userId, Map<String, dynamic> data) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    developer.log('updateProfile - userId: $userId, data: $data',
        name: 'ApiService');

    // Obtener el instructor ID basado en el userId
    final instructors = await getInstructors();
    final instructor = instructors.firstWhere(
      (inst) => inst['userId'].toString() == userId,
      orElse: () =>
          throw Exception('Instructor no encontrado para userId: $userId'),
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

    developer.log('Response status: ${response.statusCode}',
        name: 'ApiService');
    developer.log('Response body: ${response.body}', name: 'ApiService');

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Error al actualizar el perfil';
      throw Exception(message);
    }
  }

  static Future<void> uploadInstructorDocument(
      String documentType, XFile imageFile) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    String? mimeType = imageFile.mimeType;
    if (mimeType == null || mimeType.isEmpty) {
      final name = imageFile.name.toLowerCase();
      if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (name.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (name.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (name.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      }
    }

    final response = await http
        .post(
          Uri.parse('$_baseUrl/instructors/me/documents'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'documentType': documentType,
            'image': base64Image,
            'mimeType': mimeType,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al subir el documento');
      } catch (_) {
        throw Exception('Error al subir el documento: ${response.body}');
      }
    }
  }

  /// Reserva un slot vía POST /schedule/reserve/:slotId (flujo unificado con slots).
  static Future<Map<String, dynamic>> reserveSlotBySlotId(String slotId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final response = await ConnectivityService.postWithRetry(
      Uri.parse('$_baseUrl/schedule/reserve/$slotId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: '{}',
      timeout: const Duration(seconds: 15),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      // Handle ResponseFormatter: check if 'data' wrapper exists
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is Map) {
        return jsonResponse['data'] as Map<String, dynamic>;
      }
      return jsonResponse;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ?? 'Error al reservar la clase';
      throw Exception('$message (HTTP ${response.statusCode})');
    }
  }

  static Future<BookingPaymentPreference> createBookingPaymentPreference(
      int bookingId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No hay token de autenticación disponible.');
    }

    final response = await ConnectivityService.postWithRetry(
      Uri.parse('$_baseUrl/payments/booking/$bookingId/preference'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: '{}',
      timeout: const Duration(seconds: 15),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      Map<String, dynamic> data = jsonResponse;
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is Map) {
        data = jsonResponse['data'] as Map<String, dynamic>;
      }

      final initPoint = data['initPoint']?.toString() ??
          data['sandbox_init_point']?.toString() ??
          '';
      if (initPoint.isEmpty) {
        throw Exception('No se recibió la URL de pago (initPoint)');
      }

      return BookingPaymentPreference(
        initPoint: initPoint,
        preferenceId: data['preferenceId']?.toString(),
      );
    }

    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      final message = errorData['message']?.toString() ??
          'Error al crear preferencia de pago';
      final code = errorData['code']?.toString();
      if (code != null && code.isNotEmpty) {
        throw Exception('$message [code:$code]');
      }
      throw Exception('$message (HTTP ${response.statusCode})');
    } catch (e) {
      if (e is Exception && e.toString().contains('[code:')) rethrow;
      throw Exception(
          'Error al crear preferencia de pago (HTTP ${response.statusCode})');
    }
  }

  static Future<String> createPreferenceForBooking(int bookingId) async {
    final preference = await createBookingPaymentPreference(bookingId);
    return preference.initPoint;
  }

  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await ConnectivityService.postWithRetry(
      Uri.parse('$_baseUrl/auth/google'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode({'idToken': idToken}),
      timeout: const Duration(seconds: 15),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(err?['message'] ?? 'Error al iniciar sesión con Google');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    final userId = user?['id']?.toString();
    final sessionData = data['session'] as Map<String, dynamic>?;

    if (accessToken == null || userId == null || user == null) {
      throw Exception('Respuesta inválida del servidor');
    }

    await SessionManager.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      userId: userId,
      email: user['email']?.toString() ?? '',
      session: sessionData,
    );

    return {
      'token': accessToken,
      'userId': userId,
      'refreshToken': refreshToken,
      'user': user,
      'session': sessionData,
    };
  }

  /// POST /auth/apple — Sign in with Apple (iOS). Misma sesión que login/password y Google.
  static Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    required String rawNonce,
    String? givenName,
    String? familyName,
  }) async {
    final body = <String, dynamic>{
      'identityToken': identityToken,
      'rawNonce': rawNonce,
      if (givenName != null && givenName.isNotEmpty) 'givenName': givenName,
      if (familyName != null && familyName.isNotEmpty) 'familyName': familyName,
    };

    final response = await ConnectivityService.postWithRetry(
      Uri.parse('$_baseUrl/auth/apple'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode(body),
      timeout: const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(err?['message'] ?? 'Error al iniciar sesión con Apple');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    final userId = user?['id']?.toString();
    final sessionData = data['session'] as Map<String, dynamic>?;

    if (accessToken == null || userId == null || user == null) {
      throw Exception('Respuesta inválida del servidor');
    }

    final email = user['email']?.toString() ?? '';

    await SessionManager.saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      userId: userId,
      email: email,
      session: sessionData,
    );

    return {
      'token': accessToken,
      'userId': userId,
      'refreshToken': refreshToken,
      'user': user,
      'session': sessionData,
    };
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final userAgent = 'Flutter-Mobile-App/1.0';

    http.Response response;
    try {
      response = await ConnectivityService.postWithRetry(
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
        timeout: const Duration(seconds: 15),
      );
    } on http.ClientException catch (_) {
      throw Exception(ConnectivityService.connectionErrorMessage);
    } on Exception catch (e) {
      if (e.toString().contains('connection') ||
          e.toString().contains('Connection') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(ConnectivityService.connectionErrorMessage);
      }
      rethrow;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      try {
        return await _persistAuthResponse(data, email: email);
      } catch (_) {
        developer.log(
            'Login failed - Missing data. Keys: ${data.keys.toList()}',
            name: 'ApiService');
        rethrow;
      }
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      final message = errorData?['message'] ??
          errorData?['error'] ??
          'Credenciales incorrectas';
      throw Exception(message);
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final url = '$_baseUrl/users/$userId';
    try {
      final response = await AuthHttpClient.get(
        Uri.parse(url),
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        throw const SessionExpiredException();
      }
      throw Exception('Error al obtener el perfil del usuario');
    } catch (e) {
      if (e is SessionExpiredException) rethrow;
      developer.log('Error en getUserProfile: $e', name: 'ApiService');
      throw Exception('No se pudo conectar al servidor. Verificá tu conexión.');
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await ConnectivityService.postWithRetry(
      Uri.parse('$_baseUrl/users/forgot-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode({'email': email}),
      timeout: const Duration(seconds: 15),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body) as Map<String, dynamic>?;
    throw Exception(err?['message'] ?? 'Error al solicitar recuperación');
  }

  static Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    final response = await ConnectivityService.postWithRetry(
      Uri.parse('$_baseUrl/users/reset-password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: jsonEncode({'token': token, 'newPassword': newPassword}),
      timeout: const Duration(seconds: 15),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final err = jsonDecode(response.body) as Map<String, dynamic>?;
    throw Exception(err?['message'] ?? 'Error al restablecer contraseña');
  }

  static Future<Map<String, dynamic>> updateUser(
      String userId, Map<String, dynamic> data) async {
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

  static Future<Map<String, dynamic>> uploadProfileImage(
      String userId, XFile imageFile) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    developer.log('=== UPLOAD IMAGE (Base64) ===', name: 'ApiService');
    developer.log('URL: $_baseUrl/users/$userId/upload-profile-image-base64',
        name: 'ApiService');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    String? mimeType = imageFile.mimeType;
    if (mimeType == null || mimeType.isEmpty) {
      final name = imageFile.name.toLowerCase();
      if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (name.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (name.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else if (name.endsWith('.gif')) {
        mimeType = 'image/gif';
      }
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/users/$userId/upload-profile-image-base64'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image': base64Image,
        'mimeType': mimeType,
      }),
    );

    developer.log('Response status: ${response.statusCode}',
        name: 'ApiService');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return responseData;
    } else {
      developer.log('Response body: ${response.body}', name: 'ApiService');
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al subir imagen');
      } catch (_) {
        throw Exception('Error al subir imagen: ${response.body}');
      }
    }
  }

  static Future<List<Map<String, String>>> searchLocations(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 3) return [];

    final now = DateTime.now();
    final cached = _locationSearchCache[normalized];
    if (cached != null && now.isBefore(cached.expiresAt)) {
      return cached.value;
    }

    final running = _locationSearchInFlight[normalized];
    if (running != null) {
      return running;
    }

    final future = _fetchAndNormalizeLocations(normalized);
    _locationSearchInFlight[normalized] = future;
    try {
      final value = await future;
      _locationSearchCache[normalized] = _LocationCacheEntry(
        value: value,
        expiresAt: now.add(_locationSearchCacheTtl),
      );
      return value;
    } finally {
      _locationSearchInFlight.remove(normalized);
    }
  }

  static Future<List<Map<String, String>>> _fetchAndNormalizeLocations(
      String normalizedQuery) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': normalizedQuery,
      'countrycodes': 'ar',
      'format': 'jsonv2',
      'limit': '8',
      'addressdetails': '1',
      'dedupe': '1',
    });

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'ManejApp/1.0'},
    ).timeout(_locationSearchTimeout);

    if (response.statusCode != 200) {
      throw Exception('No pudimos buscar ubicaciones ahora.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return [];

    final unique = <String, Map<String, String>>{};
    for (final raw in decoded) {
      if (raw is! Map<String, dynamic>) continue;
      final address = raw['address'] as Map<String, dynamic>?;
      final lat = (raw['lat'] ?? '').toString();
      final lon = (raw['lon'] ?? '').toString();
      if (lat.isEmpty || lon.isEmpty) continue;

      final city = _firstNotEmpty([
        address?['city'],
        address?['town'],
        address?['village'],
        address?['suburb'],
        address?['neighbourhood'],
        address?['county'],
      ]);
      final state =
          _firstNotEmpty([address?['state'], address?['state_district']]);
      final country = _firstNotEmpty([address?['country']]);
      final displayName = (raw['display_name'] ?? '').toString();
      final fallbackName = displayName.split(',').first.trim();
      final main = city.isNotEmpty ? city : fallbackName;
      if (main.isEmpty) continue;

      final subtitleParts = <String>[];
      if (state.isNotEmpty &&
          !state.toLowerCase().contains(main.toLowerCase())) {
        subtitleParts.add(state);
      }
      if (country.isNotEmpty && country.toLowerCase() != 'argentina') {
        subtitleParts.add(country);
      }
      final subtitle = subtitleParts.join(' · ');
      final display = subtitle.isNotEmpty ? '$main, $state' : main;

      final dedupKey = '${main.toLowerCase()}|${state.toLowerCase()}|$lat|$lon';
      unique[dedupKey] = {
        'display': display,
        'subtitle': subtitle,
        'lat': lat,
        'lon': lon,
      };
    }

    final list = unique.values.toList();
    list.sort((a, b) {
      final da = a['display'] ?? '';
      final db = b['display'] ?? '';
      final qa = da.toLowerCase().startsWith(normalizedQuery) ? 0 : 1;
      final qb = db.toLowerCase().startsWith(normalizedQuery) ? 0 : 1;
      if (qa != qb) return qa - qb;
      return da.compareTo(db);
    });

    return list.take(6).toList();
  }

  static String _firstNotEmpty(List<dynamic> values) {
    for (final value in values) {
      final txt = (value ?? '').toString().trim();
      if (txt.isNotEmpty) return txt;
    }
    return '';
  }

  static Future<void> changePassword(
      String currentPassword, String newPassword) async {
    final response = await AuthHttpClient.patch(
      Uri.parse('$_baseUrl/users/me/password'),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error al cambiar contraseña');
    }
  }

  static Future<void> changeEmail(String newEmail, String password) async {
    final response = await AuthHttpClient.patch(
      Uri.parse('$_baseUrl/users/me/email'),
      body: jsonEncode({
        'newEmail': newEmail,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error al cambiar email');
    }
  }

  // ===========================
  // NOTIFICACIONES
  // ===========================

  static Future<void> saveFcmToken(String fcmToken) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) return;
    final response = await http.post(
      Uri.parse('$_baseUrl/users/fcm-token'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    if (response.statusCode != 200) {
      developer.log(
        'saveFcmToken ${response.statusCode} ${response.body}',
        name: 'ApiService',
      );
      throw Exception(
          'No se pudo registrar el dispositivo para notificaciones');
    }
  }

  static Future<void> deleteFcmTokenRemote() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) return;
    try {
      await http.delete(
        Uri.parse('$_baseUrl/users/fcm-token'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      developer.log('deleteFcmTokenRemote: $e', name: 'ApiService');
    }
  }

  static Future<Map<String, dynamic>?> fetchNotificationPreferences() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) return null;
    final response = await http.get(
      Uri.parse('$_baseUrl/users/notification-preferences'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return null;
    return body;
  }

  static Future<void> putNotificationPreferences({
    required bool emailNotifications,
    required bool pushNotifications,
  }) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');
    final response = await http.put(
      Uri.parse('$_baseUrl/users/notification-preferences'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'emailNotifications': emailNotifications,
        'pushNotifications': pushNotifications,
      }),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      final msg =
          err is Map ? (err['message'] ?? err['error'])?.toString() : null;
      throw Exception(msg ?? 'Error al guardar preferencias');
    }
  }

  static Future<void> logout() async {
    await SessionManager.clearSession();
    await BiometricService.clearPreference();
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    final success = await SessionManager.tryRefresh();
    if (!success) {
      throw Exception('La sesión venció. Iniciá sesión nuevamente.');
    }
    final newToken = await SessionManager.accessToken;
    final newRefresh = await SessionManager.refreshToken;
    return {'token': newToken, 'refreshToken': newRefresh};
  }

  static Future<bool> isSessionValid() => SessionManager.hasSession;

  // ===========================
  // AUTH EXTENDED
  // ===========================

  static Future<Map<String, dynamic>> getMe() async {
    if (!await SessionManager.hasSession) {
      throw const SessionExpiredException('No autenticado');
    }

    final response = await AuthHttpClient.get(
      Uri.parse('$_baseUrl/auth/me'),
      timeout: const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    throw Exception('Error obteniendo información del usuario');
  }

  /// POST /users/me/delete-account — anonimización en servidor (no borra historial de clases/pagos).
  static Future<void> deleteAccount({
    required String confirmPhrase,
    String? password,
  }) async {
    final url = Uri.parse('$_baseUrl/users/me/delete-account');
    final payload = <String, dynamic>{
      'confirmPhrase': confirmPhrase,
      if (password != null && password.isNotEmpty) 'password': password,
    };
    final response = await AuthHttpClient.post(
      url,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) return;
    String? msg;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        msg = (decoded['message'] ?? decoded['error'])?.toString();
      }
    } catch (_) {}
    throw Exception(msg ?? 'No se pudo eliminar la cuenta');
  }

  /// GET /instructors/me. Returns full profile if role is INSTRUCTOR.
  static Future<Map<String, dynamic>?> getInstructorMeOrNull() async {
    if (!await SessionManager.hasSession) return null;

    final url = Uri.parse('$_baseUrl/instructors/me');
    try {
      final response = await AuthHttpClient.get(
        url,
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      if (response.statusCode == 401) {
        throw const SessionExpiredException();
      }
      return null;
    } on SessionExpiredException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// GET /instructors/me/mercadopago/connect → authorizationUrl (OAuth MP).
  static Future<String> getInstructorMercadoPagoConnectUrl() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/instructors/me/mercadopago/connect'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    if (response.statusCode != 200 || body == null) {
      final msg = body?['error'] ??
          body?['message'] ??
          'No se pudo obtener URL de Mercado Pago';
      throw Exception(msg.toString());
    }

    final data = body['data'] as Map<String, dynamic>?;
    final url = data?['authorizationUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Respuesta inválida del servidor (sin authorizationUrl)');
    }
    return url;
  }

  /// GET /instructors/me/mercadopago/status — sin tokens sensibles.
  static Future<Map<String, dynamic>> getInstructorMercadoPagoStatus() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/instructors/me/mercadopago/status'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>?;
    if (response.statusCode != 200 || body == null) {
      final msg = body?['error'] ??
          body?['message'] ??
          'No se pudo consultar Mercado Pago';
      throw Exception(msg.toString());
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    throw Exception('Respuesta inválida del servidor');
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

  static Future<void> updateInstructor(
      String instructorId, Map<String, dynamic> data) async {
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

    developer.log('Response status: ${response.statusCode}',
        name: 'ApiService');
    developer.log('Response body: ${response.body}', name: 'ApiService');

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error actualizando instructor');
    }
  }

  // ===========================
  // CARS MANAGEMENT
  // ===========================

  static Future<Map<String, dynamic>> createCar(
      Map<String, dynamic> carData) async {
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

  static Future<void> updateCar(
      String carId, Map<String, dynamic> carData) async {
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

  // ===========================
  // PREMIUM RESERVATIONS (FASE 2A)
  // ===========================

  static Future<List<dynamic>> getStudentUpcomingReservationsPremium() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/classes/student/upcoming'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo próximas reservas premium de alumno');
    }
  }

  static Future<List<dynamic>> getStudentHistoryReservationsPremium() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/classes/student/history'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo historial premium de alumno');
    }
  }

  static Future<Map<String, dynamic>> getStudentReservationDetailPremium(
      String classId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/classes/student/$classId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo detalle premium de alumno');
    }
  }

  static Future<List<dynamic>>
      getInstructorUpcomingReservationsPremium() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/classes/instructor/upcoming'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception(
          'Error obteniendo próximas reservas premium de instructor');
    }
  }

  static Future<List<dynamic>> getInstructorHistoryReservationsPremium() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/classes/instructor/history'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error obteniendo historial premium de instructor');
    }
  }

  static Future<Map<String, dynamic>> getInstructorReservationDetailPremium(
      String classId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/classes/instructor/$classId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error obteniendo detalle premium de instructor');
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

  static Future<void> updateDrivingClass(
      String classId, Map<String, dynamic> classData) async {
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
      final decoded = jsonDecode(response.body);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      if (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>) {
        return decoded['data'] as List<dynamic>;
      }
      throw Exception('Formato de pagos inesperado');
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

  // ===========================
  // SCHEDULE MANAGEMENT
  // ===========================

  static Future<Map<String, dynamic>> createScheduleSlot(
      Map<String, dynamic> slotData) async {
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

  static Future<Map<String, dynamic>> getReservationPreview(
      String slotId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/schedule/preview/$slotId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(
          errorData?['message'] ?? 'Error obteniendo preview de reserva');
    }
  }

  static Future<List<dynamic>> getInstructorSchedule(
      String instructorId) async {
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
    if (slotId.isEmpty) {
      throw Exception('ID del slot no puede estar vacío');
    }

    final url = Uri.parse('$_baseUrl/schedule/reserve/$slotId');
    final response = await AuthHttpClient.post(url, body: jsonEncode({}));

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

  /// Reprograma una clase confirmada a otro slot del mismo instructor.
  /// POST /schedule/reschedule/:bookingId con { newSlotId }.
  static Future<Map<String, dynamic>> rescheduleReservation(
    String bookingId,
    String newSlotId,
  ) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.post(
      Uri.parse('$_baseUrl/schedule/reschedule/$bookingId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'newSlotId': newSlotId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body);
      if (errorData is Map<String, dynamic>) {
        throw Exception(errorData['message'] ?? 'Error reprogramando la clase');
      }
      throw Exception('Error reprogramando la clase');
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

  /// @Deprecated Usar [createPreferenceForBooking]. El endpoint legacy fue eliminado.
  @Deprecated(
      'Usar createPreferenceForBooking(bookingId) — flujo V1 por reserva')
  static Future<Map<String, dynamic>> mpCreatePreference({
    required int drivingClassId,
    required int amount,
    required String description,
    String? payerEmail,
    String? successUrl,
    String? failureUrl,
    String? pendingUrl,
  }) async {
    final initPoint = await createPreferenceForBooking(drivingClassId);
    return {
      'data': {
        'initPoint': initPoint,
        'preferenceId': null,
      },
    };
  }

  /// Consulta estado de pago MP/DB. [identifier] puede ser bookingId, preferenceId, paymentId MP o externalReference.
  static Future<PaymentStatusResult> mpGetPaymentStatus(
      String identifier) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw const SessionExpiredException('No autenticado');

    final encoded = Uri.encodeComponent(identifier);
    final response = await AuthHttpClient.get(
      Uri.parse('$_baseUrl/payments/mercadopago/status/$encoded'),
      timeout: const Duration(seconds: 12),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      Map<String, dynamic> data = jsonResponse;
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is Map) {
        data = jsonResponse['data'] as Map<String, dynamic>;
      }
      return PaymentStatusResult.fromApiMap(data);
    }
    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }

    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message']?.toString() ??
          'Error al consultar estado del pago');
    } catch (e) {
      if (e is SessionExpiredException) rethrow;
      if (e is Exception && e.toString().contains('Error al consultar')) {
        rethrow;
      }
      throw Exception(
          'Error al consultar estado del pago (HTTP ${response.statusCode})');
    }
  }

  // ===========================
  // ADMIN
  // ===========================

  static Future<void> manageUser(String userId,
      {required bool isActive}) async {
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
  // MESSAGES
  // ===========================

  static Future<Map<String, dynamic>> sendMessage(
      int receiverId, String content) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.post(
      Uri.parse('$_baseUrl/messages/send'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'receiverId': receiverId, 'content': content}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'] as Map<String, dynamic>;
    } else {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error enviando mensaje');
    }
  }

  static Future<List<dynamic>> getConversations() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/messages/conversations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'] as List<dynamic>;
    } else {
      throw Exception('Error obteniendo conversaciones');
    }
  }

  static Future<List<dynamic>> getConversationMessages(
      int conversationId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/messages/conversations/$conversationId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'] as List<dynamic>;
    } else {
      throw Exception('Error obteniendo mensajes');
    }
  }

  static Future<int> getUnreadMessagesCount() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/messages/unread-count'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data']['unreadCount'] as int;
    } else {
      throw Exception('Error obteniendo contador de mensajes');
    }
  }

  static Future<void> markConversationAsRead(int conversationId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.put(
      Uri.parse('$_baseUrl/messages/conversations/$conversationId/read'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error marcando mensajes como leídos');
    }
  }

  static Future<bool> canContactInstructor(int instructorId) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) throw Exception('No autenticado');

    final response = await http.get(
      Uri.parse('$_baseUrl/payments'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final payments = jsonDecode(response.body) as List<dynamic>;
      return payments.any((p) {
        final drivingClass = p['drivingClass'] as Map<String, dynamic>?;
        return p['status'] == 'paid' &&
            drivingClass?['instructorId'] == instructorId;
      });
    }
    return false;
  }

  // ===========================
  // EMAIL VERIFICATION
  // ===========================

  static Future<void> verifyEmail(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error en verificación');
    }
  }

  static Future<void> resendVerification(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
      throw Exception(errorData?['message'] ?? 'Error al reenviar');
    }
  }

  /// Verifica si el usuario ya completó la verificación de email (no requiere auth).
  static Future<bool> checkVerificationStatus(String userId) async {
    try {
      final response = await ConnectivityService.getWithRetry(
        Uri.parse('$_baseUrl/users/verification-status/$userId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>?;
        return data?['verified'] == true;
      }
      return false;
    } catch (e) {
      developer.log('Error en checkVerificationStatus: $e', name: 'ApiService');
      return false;
    }
  }
}

class _LocationCacheEntry {
  _LocationCacheEntry({
    required this.value,
    required this.expiresAt,
  });

  final List<Map<String, String>> value;
  final DateTime expiresAt;
}
