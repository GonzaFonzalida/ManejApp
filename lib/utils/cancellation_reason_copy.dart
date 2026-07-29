/// Copy humano para motivos de cancelación de reservas (backend `cancellationReason`).
/// Perspectiva del alumno.
String humanizeCancellationReason(String? reason) {
  switch (reason?.toUpperCase()) {
    case 'HOLD_EXPIRED':
      return 'La reserva se canceló porque el tiempo para completar el pago expiró.';
    case 'PAYMENT_FAILED':
      return 'El pago no pudo confirmarse.';
    case 'STUDENT_CANCELLED':
      return 'Cancelaste esta reserva.';
    case 'INSTRUCTOR_CANCELLED':
      return 'El instructor canceló esta reserva.';
    case 'ADMIN_CANCELLED':
      return 'La reserva fue cancelada por soporte.';
    case 'PAYMENT_CONFLICT':
      return 'Hubo un problema con el pago. Estamos revisándolo.';
    case 'SYSTEM_CANCELLED':
    case 'UNKNOWN':
    case null:
    case '':
      return 'La reserva fue cancelada.';
    default:
      return 'La reserva fue cancelada.';
  }
}

/// Copy humano para motivos de cancelación desde la perspectiva del instructor.
String humanizeCancellationReasonForInstructor(String? reason) {
  switch (reason?.toUpperCase()) {
    case 'HOLD_EXPIRED':
      return 'La reserva se canceló porque el alumno no completó el pago a tiempo.';
    case 'PAYMENT_FAILED':
      return 'El pago no pudo confirmarse.';
    case 'STUDENT_CANCELLED':
      return 'El alumno canceló esta reserva.';
    case 'INSTRUCTOR_CANCELLED':
      return 'Cancelaste esta reserva.';
    case 'ADMIN_CANCELLED':
      return 'La reserva fue cancelada por soporte.';
    case 'PAYMENT_CONFLICT':
      return 'Hubo un problema con el pago. Soporte lo está revisando.';
    case 'SYSTEM_CANCELLED':
    case 'UNKNOWN':
    case null:
    case '':
      return 'La reserva fue cancelada.';
    default:
      return 'La reserva fue cancelada.';
  }
}
