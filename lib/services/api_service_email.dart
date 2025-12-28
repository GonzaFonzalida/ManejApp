import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';

class ApiServiceEmail {
  static String get _baseUrl => '${ConfigService.baseUrl}/api/v1';

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
}
