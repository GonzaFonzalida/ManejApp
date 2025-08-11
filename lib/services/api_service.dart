import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use the IP address provided by the user.
  static const baseUrl = 'http://192.168.0.3:3000/users';

  static Future<String> login(String email, String password) async {
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
        final data = jsonDecode(response.body);
        // The image shows the response body doesn't have a 'token' field.
        // It returns user data like 'id', 'dni', 'email', etc.
        // You should handle this based on your API's actual response.
        // For now, let's assume it returns a token or at least a success message.
        // If your API doesn't return a token, you can simply return a success string.
        if (data.containsKey('token')) {
          return data['token'] as String;
        } else {
          // If no token is returned, you can return an empty string or a success message.
          return 'Login successful';
        }
      } else {
        // If the server responds with an error, throw an exception.
        final data = jsonDecode(response.body);
        final errorMessage = data['message'] ?? 'Credenciales inválidas';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // If there's a connection error, throw an exception.
      // Make sure the server is running on your computer.
      throw Exception('Error de conexión. Intenta de nuevo más tarde.');
    }
  }

  // Your register method is fine and doesn't need changes.
  static Future<String> register(String name, String surname, String email,
      String password, String dni, String birthDate) async {
    // ... (rest of the register code)
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
            'birthDate': birthDateObject.toIso8601String()
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