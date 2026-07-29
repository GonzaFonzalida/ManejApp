import 'dart:async';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import '../services/notification_service.dart';
import '../services/session_manager.dart';
import '../screens/login_screen.dart';
import '../screens/choose_role_screen.dart';
import '../utils/google_auth_helper.dart';
import '../utils/apple_auth_helper.dart';
import '../utils/role_router.dart';
import '../utils/user_facing_error.dart';

const storage = appSecureStorage;

Future<void> navigateAfterLogin(
    BuildContext context, String targetRoute) async {
  if (!context.mounted) return;
  if (targetRoute == ChooseRoleScreen.routeName) {
    final uid = await storage.read(key: 'user_id');
    if (uid != null && uid.isNotEmpty) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, ChooseRoleScreen.routeName,
          arguments: uid);
      return;
    }
  }
  if (!context.mounted) return;
  Navigator.pushReplacementNamed(context, targetRoute);
}

/// Resuelve la ruta post-login/register sin caer en pantallas de otro rol.
/// Retorna `true` si la navegación fue exitosa.
Future<bool> navigateAfterAuth(
  BuildContext context,
  String routingContext, {
  RoleRouterOverrides? overrides,
}) async {
  try {
    final targetRoute = await RoleRouter.resolveRouteForCurrentUser(
      context: routingContext,
      overrides: overrides,
    );
    debugPrint('[RoleRouter] $routingContext → $targetRoute');
    if (!context.mounted) return false;
    await navigateAfterLogin(context, targetRoute);
    unawaited(NotificationService.registerTokenWithBackendIfLoggedIn());
    return true;
  } catch (e) {
    debugPrint('Error obteniendo rol del usuario: $e');
    if (!context.mounted) return false;
    handlePostAuthRoutingFailure(context, e);
    return false;
  }
}

void handlePostAuthRoutingFailure(BuildContext context, Object error) {
  RoleRouter.setLastError(error.toString());
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text(
        'Iniciaste sesión, pero no pudimos verificar tu perfil. Revisá tu conexión e intentá de nuevo.',
      ),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: 'Reintentar',
        onPressed: () {
          unawaited(() async {
            await navigateAfterAuth(context, 'retry');
          }());
        },
      ),
    ),
  );
}

class LoginController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = false;
  bool isLoading = false;

  Future<void> loadSavedCredentials(VoidCallback onUpdate) async {
    try {
      final remembered = await SessionManager.getRememberedEmail();
      rememberMe = remembered.rememberMe;
      if (rememberMe && remembered.email != null) {
        emailController.text = remembered.email!.trim();
      }
      onUpdate();
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> saveRememberMe() async {
    if (rememberMe) {
      await SessionManager.setRememberEmail(emailController.text.trim());
    } else {
      await SessionManager.clearRememberEmail();
    }
  }

  Future<void> submit(BuildContext context, VoidCallback onUpdate) async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }

    formKey.currentState!.save();
    isLoading = true;
    onUpdate();

    try {
      await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      await saveRememberMe();

      if (!context.mounted) return;

      final routed = await navigateAfterAuth(context, 'login(password)');
      if (!context.mounted) return;
      if (routed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso')),
        );
      }
    } catch (e) {
      debugPrint('Error en login: $e');
      if (!context.mounted) return;
      final msg = humanizeApiError(e);
      final isConnectionError = msg.contains('No se pudo conectar') ||
          msg.contains('servidor') ||
          msg.contains('conexión');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 10),
          action: isConnectionError
              ? SnackBarAction(
                  label: 'Reintentar',
                  onPressed: () => submit(context, onUpdate),
                )
              : null,
        ),
      );
    } finally {
      isLoading = false;
      onUpdate();
    }
  }

  Future<void> loginWithGoogle(
      BuildContext context, VoidCallback onUpdate) async {
    isLoading = true;
    onUpdate();
    try {
      final result = await GoogleAuthHelper.signIn();
      if (result == null) {
        isLoading = false;
        onUpdate();
        return;
      }

      if (!context.mounted) return;
      final routed = await navigateAfterAuth(context, 'login(google)');
      if (context.mounted && routed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión con Google exitoso')),
        );
      }
    } catch (e) {
      debugPrint('Error en login con Google: $e');
      if (!context.mounted) return;
      final msg = humanizeApiError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
    } finally {
      isLoading = false;
      onUpdate();
    }
  }

  Future<void> loginWithApple(
      BuildContext context, VoidCallback onUpdate) async {
    isLoading = true;
    onUpdate();
    try {
      final result = await AppleAuthHelper.signIn();
      if (result == null) {
        isLoading = false;
        onUpdate();
        return;
      }

      if (!context.mounted) return;
      final routed = await navigateAfterAuth(context, 'login(apple)');
      if (context.mounted && routed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión con Apple exitoso')),
        );
      }
    } catch (e) {
      debugPrint('Error en login con Apple: $e');
      if (!context.mounted) return;
      final msg = humanizeApiError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
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
      await GoogleAuthHelper.signOut();
      await NotificationService.onLogout();
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
