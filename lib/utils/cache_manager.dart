import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheManager {
  static const Duration _defaultExpiry = Duration(minutes: 15);

  static Future<void> save(String key, dynamic data, {Duration? expiry}) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime =
        DateTime.now().add(expiry ?? _defaultExpiry).millisecondsSinceEpoch;

    final cacheData = {
      'data': data,
      'expiry': expiryTime,
    };

    await prefs.setString(key, jsonEncode(cacheData));
  }

  static Future<dynamic> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);

    if (cached == null) return null;

    try {
      final cacheData = jsonDecode(cached);
      final expiry = cacheData['expiry'] as int;

      if (DateTime.now().millisecondsSinceEpoch > expiry) {
        await prefs.remove(key);
        return null;
      }

      return cacheData['data'];
    } catch (e) {
      return null;
    }
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_'));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }
}
