import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Asegúrate de que esta URL sea la correcta para tu API
  static const baseUrl = 'http://192.168.0.3:3000/users';

  static Future<String> login(String email, String password) async {
    // La validación de campos vacíos debería estar en el frontend,
    // pero si ocurre aquí, debería lanzar un error.
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Por favor, ingresa tu correo y contraseña');
    }

    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Si el login es exitoso, devuelve el token
        final data = jsonDecode(response.body);
        return data['token'];
      } else {
        // Si el servidor responde con un error, lanza una excepción.
        // El mensaje de error puede ser más específico si tu backend lo envía.
        throw Exception('Credenciales inválidas');
      }
    } catch (e) {
      // Si hay un error de conexión (timeout, etc.), lanza una excepción.
      throw Exception('Error de conexión. Intenta de nuevo más tarde.');
    }
  }

  // Este método de registro está bien y no necesita cambios.
  static Future<String> register(String name, String surname, String email,
      String password, String dni, String birthDate) async {
    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        dni.isEmpty ||
        birthDate.isEmpty) {
      throw Exception('Todos los campos son obligatorios');
    }

    final birthDateObject = DateTime.parse(birthDate);

    final url = Uri.parse('$baseUrl/register');
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
      if (data['token'] is String) {
        return data['token'] as String;
      } else {
        throw Exception(
            'Error en registro: El token no se encontró o no es válido.');
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
}
