import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'https://api.maneapp.com'; // Reemplazar con URL real

  // Método para login
  static Future<String> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('El email y la contraseña no pueden estar vacíos');
    }
    final url = Uri.parse('$baseUrl/login');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] == null) {
        throw Exception('No se encontró el token en la respuesta');
      }
      return data['token'];
    } else {
      throw Exception('Error en login: ${response.body}');
    }
  }

  // Método para registro
  static Future<String> register(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('El nombre, email y contraseña no pueden estar vacíos');
    }
    final url = Uri.parse('$baseUrl/register');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': name, 'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['token'] == null) {
        throw Exception('No se encontró el token en la respuesta');
      }
      return data['token'];
    } else {
      throw Exception('Error en registro: ${response.body}');
    }
  }
}