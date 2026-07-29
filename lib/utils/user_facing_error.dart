/// Mensajes claros para el usuario (sin stack traces ni ruido técnico).
String humanizeApiError(Object? error) {
  if (error == null) {
    return 'Algo salió mal. Probá de nuevo en un momento.';
  }
  var raw = error.toString().trim();
  raw = raw.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();

  final lower = raw.toLowerCase();
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset')) {
    return 'No pudimos conectar. Revisá tu internet e intentá otra vez.';
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'Está tardando más de lo esperado. Intentá de nuevo.';
  }
  if (lower.contains('401') ||
      lower.contains('403') ||
      lower.contains('no autenticado') ||
      lower.contains('sesión')) {
    return 'Tu sesión puede haber expirado. Volvé a iniciar sesión.';
  }
  if (lower.contains('404') || lower.contains('no encontrad')) {
    return 'No encontramos lo que buscabas. Si sigue pasando, escribinos.';
  }
  if (raw.length > 160) {
    return '${raw.substring(0, 157)}…';
  }
  return raw.isEmpty ? 'Algo salió mal. Probá de nuevo.' : raw;
}

/// Mensaje para fallos al crear preferencia MP tras reservar (409 OAuth instructor).
String messageForPaymentPreferenceError(Object? error,
    {bool bookingCreated = false}) {
  final raw = error?.toString() ?? '';
  if (raw.contains('INSTRUCTOR_MP_NOT_CONNECTED')) {
    return 'El instructor todavía no conectó su cuenta de Mercado Pago. Probá más tarde o elegí otro instructor.';
  }
  if (raw.contains('INSTRUCTOR_MP_TOKEN_EXPIRED')) {
    return 'No pudimos iniciar el pago porque la cuenta de Mercado Pago del instructor necesita reconectarse. Probá más tarde.';
  }
  final human = humanizeApiError(error);
  if (bookingCreated) {
    return 'La reserva quedó pendiente, pero no se pudo iniciar el pago. '
        '${human.endsWith('.') ? human.substring(0, human.length - 1) : human}. '
        'Podés reintentar desde el detalle de la reserva.';
  }
  return human;
}
