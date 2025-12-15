import 'dart:convert';
import 'package:http/http.dart' as http;

class ConfigService {
  static String _baseUrl = 'http://72.60.166.178:3000';
  static const String _fallbackUrl = 'http://72.60.166.178:3000';

  static Future<void> loadConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$_fallbackUrl/api/v1/config'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _baseUrl = data['baseUrl'] ?? _fallbackUrl;
      }
    } catch (e) {
      _baseUrl = _fallbackUrl;
    }
  }

  static String get baseUrl => _baseUrl;
}
