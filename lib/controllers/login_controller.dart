import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';

class LoginController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = false;
  bool isLoading = false;

  Future<void> loadSavedCredentials(VoidCallback onUpdate) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');
    rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe && savedEmail != null && savedPassword != null) {
      emailController.text = savedEmail.trim();
      passwordController.text = savedPassword.trim();
    }
    onUpdate();
  }

  Future<void> saveCredentials(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);

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
    if (!formKey.currentState!.validate()) return;

    formKey.currentState!.save();
    isLoading = true;
    onUpdate();

    try {
      final token = await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      await saveCredentials(token);

      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
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

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }
}
