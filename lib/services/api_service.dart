import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
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

  // Método de registro modificado para no gestionar tokens.
  static Future<void> register(
    String name,
    String surname,
    String email,
    String password,
    String dni,
    String birthDate,
  ) async {
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

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      final errorMessage = data['message'] ?? 'Error desconocido en registro';
      if (errorMessage.contains("El campo 'email' ya está en uso.")) {
        throw Exception("Email ya en uso!");
      }
      throw Exception('Error en registro: $errorMessage');
    }
    // Si la respuesta es exitosa (código 201), no se hace nada con el token.
    // La función se completa sin retornar ni verificar un token.
  }

  // Nueva función para actualizar el rol del usuario en el backend
  static Future<void> updateRole(String token, int userId, String role) async {
    final url = Uri.parse('$baseUrl/$userId/role');

    // Aquí enviamos el nuevo rol.
    final response = await http
        .put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'role': role}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      final errorMessage = data['message'] ?? 'Error al actualizar el rol';
      throw Exception(errorMessage);
    }
  }

  // Nueva función para crear un instructor
  static Future<void> createInstructor(
    String token,
    int userId,
    String licenseNumber,
    int experienceYears,
  ) async {
    final url = Uri.parse('http://192.168.0.3:3000/instructors');

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'userId': userId,
            'licenseNumber': licenseNumber,
            'experienceYears': experienceYears,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      final errorMessage =
          data['message'] ?? 'Error al crear el perfil de instructor';
      throw Exception(errorMessage);
    }
  }
}
