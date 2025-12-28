import 'package:flutter/material.dart';

class ErrorMessage {
  static String parse(dynamic error) {
    if (error is String) return error;
    
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Error de conexión. Verifica tu internet.';
    }
    if (errorStr.contains('timeout')) {
      return 'La solicitud tardó demasiado. Intenta nuevamente.';
    }
    if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
      return 'Sesión expirada. Inicia sesión nuevamente.';
    }
    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return 'No tienes permisos para realizar esta acción.';
    }
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'Recurso no encontrado.';
    }
    if (errorStr.contains('500') || errorStr.contains('server')) {
      return 'Error del servidor. Intenta más tarde.';
    }
    
    return 'Ocurrió un error inesperado.';
  }

  static void show(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(parse(error)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
