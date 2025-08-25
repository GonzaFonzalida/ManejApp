import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'http://192.168.0.63:3000';

  static Future<String> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Por favor, ingresa tu correo y contraseña');
    }

    final url = Uri.parse('$baseUrl/users/login');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('token')) {
          return data['token'] as String;
        } else {
          return 'Login successful';
        }
      } else {
        final data = jsonDecode(response.body);
        final errorMessage = data['message'] ?? 'Credenciales inválidas';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error de conexión. Intenta de nuevo más tarde.');
    }
  }

  static Future<Map<String, dynamic>> register(
    String name,
    String surname,
    String email,
    String password,
    String dni,
    String birthDate,
  ) async {
    final url = Uri.parse('$baseUrl/users/register');
    final birthDateObject = DateTime.parse(birthDate);

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'surname': surname,
            'email': email,
            'password': password,
            'dni': dni,
            'birthDate': birthDateObject.toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data.containsKey('token') && data.containsKey('userId')) {
        return {
          'token': data['token'] as String,
          'userId': data['userId'] as int,
        };
      } else {
        throw Exception('Respuesta del servidor incompleta');
      }
    } else {
      final data = jsonDecode(response.body);
      final errorMessage = data['message'] ?? 'Error desconocido en registro';
      if (errorMessage.contains("El campo 'email' ya está en uso.")) {
        throw Exception("Email ya en uso!");
      }
      throw Exception('Error en registro: $errorMessage');
    }
  }

  /// ⚠️ ADVERTENCIA: Esta función se ha modificado para pruebas.
  /// No incluye un token de autorización, lo que la hace muy insegura.
  /// Revierta este cambio para la producción.
  static Future<void> createInstructor(
    int userId,
    String licenseNumber,
    int experienceYears, {
    int? carId,
  }) async {
    final url = Uri.parse('$baseUrl/instructors/register');
    try {
      final body = {
        'userId': userId,
        'licenseNumber': licenseNumber,
        'experienceYears': experienceYears,
        'carId': carId ?? 1,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 201) {
        final data = jsonDecode(response.body);
        final errorMessage = data['message'] ?? 'Error al crear el perfil de instructor';
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }
}
