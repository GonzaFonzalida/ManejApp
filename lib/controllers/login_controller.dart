import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

const storage = FlutterSecureStorage();

class LoginController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = false;
  bool isLoading = false;

  Future<void> loadSavedCredentials(VoidCallback onUpdate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('email');
      final savedPassword = prefs.getString('password');
      rememberMe = prefs.getBool('rememberMe') ?? false;

      if (rememberMe && savedEmail != null && savedPassword != null) {
        emailController.text = savedEmail.trim();
        passwordController.text = savedPassword.trim();
      }
      onUpdate();
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> saveCredentials(String? accessToken) async {
    final prefs = await SharedPreferences.getInstance();

    // 🔹 Guardamos el access token en secure storage
    if (accessToken != null) {
      await storage.write(key: 'auth_token', value: accessToken);
    }

    if (rememberMe) {
      await prefs.setString('email', emailController.text.trim());
      await prefs.setString('password', passwordController.text.trim());
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  Future<void> submit(BuildContext context, VoidCallback onUpdate) async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) return;

    formKey.currentState!.save();
    isLoading = true;
    onUpdate();

    try {
      // 🔹 Login con API - ahora incluye creación de sesión
      final result = await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      final accessToken = result['token']?.toString();
      final userId = result['userId']?.toString();
      final refreshToken = result['refreshToken']?.toString();
      final sessionData = result['session'] as Map<String, dynamic>?;

      await saveCredentials(accessToken);
      if (userId != null) {
        await storage.write(key: 'user_id', value: userId);
      }
      if (refreshToken != null) {
        await storage.write(key: 'refresh_token', value: refreshToken);
      }
      if (sessionData != null) {
        // Guardar datos de sesión para referencia local
        await storage.write(key: 'session_id', value: sessionData['id']?.toString() ?? '');
        await storage.write(key: 'session_created_at', value: sessionData['createdAt']?.toString() ?? '');
        await storage.write(key: 'session_expires_at', value: sessionData['expiresAt']?.toString() ?? '');
        debugPrint('Sesión creada exitosamente: ${sessionData['id']}');
      }

      if (!context.mounted) return;
      
      // Determinar la ruta según el rol del usuario
      try {
        final userInfo = await ApiService.getMe();
        debugPrint('UserInfo completo: $userInfo');
        final userRole = userInfo['user']?['role']?.toString().toUpperCase();
        debugPrint('Rol detectado: $userRole');
        
        if (!context.mounted) return;
        
        String targetRoute;
        if (userRole == 'ADMIN') {
          targetRoute = '/admin_dashboard';
          debugPrint('Redirigiendo a admin dashboard');
        } else if (userRole == 'INSTRUCTOR') {
          targetRoute = '/instructor_dashboard';
          debugPrint('Redirigiendo a instructor dashboard');
        } else {
          targetRoute = '/student_dashboard';
          debugPrint('Redirigiendo a student dashboard');
        }
        
        Navigator.pushReplacementNamed(context, targetRoute);
      } catch (e) {
        debugPrint('Error obteniendo rol del usuario: $e');
        // Fallback al home normal si hay error obteniendo el rol
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión exitoso')),
      );
    } catch (e) {
      debugPrint('Error en login: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error en inicio de sesión: $e')),
      );
    } finally {
      isLoading = false;
      onUpdate();
    }
  }

  void forgotPassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de recuperación de contraseña'),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    try {
      await ApiService.logout();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada exitosamente')),
      );
    } catch (e) {
      debugPrint('Error en logout: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
