import 'package:flutter/material.dart';
import 'package:manejapp/utils/app_feedback.dart';

class ErrorMessage {
  static String parse(dynamic error) {
    if (error is String) return error;

    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Error de conexión. Verificá tu acceso a internet.';
    }
    if (errorStr.contains('timeout')) {
      return 'La solicitud tardó demasiado. Intentá nuevamente.';
    }
    if (errorStr.contains('401') || errorStr.contains('unauthorized')) {
      return 'La sesión venció. Iniciá sesión nuevamente.';
    }
    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return 'No tenés permiso para realizar esta acción.';
    }
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'Recurso no encontrado.';
    }
    if (errorStr.contains('500') || errorStr.contains('server')) {
      return 'Hubo un problema en el servidor. Intentá más tarde.';
    }

    return 'Ocurrió un error inesperado.';
  }

  static void show(BuildContext context, dynamic error) {
    AppFeedback.showError(context, parse(error));
  }

  static void showSuccess(BuildContext context, String message) {
    AppFeedback.showSuccess(context, message);
  }
}
