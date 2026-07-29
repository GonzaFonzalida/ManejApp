import 'package:manejapp/config/premium_booking_ui.dart';

/// Microcopy educativo para estados de reserva y pago (sin enums técnicos).
class ReservationStatusEducation {
  ReservationStatusEducation._();

  /// Explicación corta bajo chips o en detalle según estado de reserva y pago.
  static String? contextualHint({
    required String status,
    required String paymentStatus,
  }) {
    if (PremiumBookingUi.isManualReviewPayment(paymentStatus)) {
      return 'Pago en revisión: no hagas otro pago por ahora.';
    }

    final pay = paymentStatus.toLowerCase().trim();
    if (pay == 'rejected' || pay == 'cancelled') {
      return 'Pago rechazado: podés intentar de nuevo si el horario sigue disponible.';
    }

    switch (status) {
      case 'PENDING_PAYMENT':
        return 'Pendiente de pago: el horario todavía no está asegurado.';
      case 'CONFIRMED':
        return 'Confirmada: el pago fue aprobado y la clase quedó reservada.';
      case 'CANCELLED':
        return 'Cancelada: esta reserva ya no está activa.';
      case 'COMPLETED':
        return 'Completada: la clase ya se realizó.';
      default:
        return null;
    }
  }

  /// Hint para pantalla de detalle alumno (más orientado a acción).
  static String? studentDetailGuidance({
    required String status,
    required String paymentStatus,
  }) {
    if (PremiumBookingUi.isManualReviewPayment(paymentStatus)) {
      return 'No hagas otro pago por ahora. Estamos revisando la operación. '
          'Podés actualizar el estado desde esta pantalla.';
    }
    if (status == 'PENDING_PAYMENT' ||
        PremiumBookingUi.isPendingPaymentStatus(paymentStatus)) {
      return 'Esta reserva todavía no está confirmada. Completá el pago para asegurar el horario.';
    }
    if (status == 'CONFIRMED') {
      return 'Tu clase está confirmada. Revisá día, horario y ubicación antes de asistir.';
    }
    if (status == 'CANCELLED' || status == 'COMPLETED') {
      return null;
    }
    return contextualHint(status: status, paymentStatus: paymentStatus);
  }

  /// Hint post-pago en pantalla de éxito.
  static String? successScreenHint(String paymentStateKey) {
    switch (paymentStateKey) {
      case 'pending':
      case 'checking':
      case 'networkError':
        return 'Podés actualizar el estado desde esta pantalla o revisar Mis reservas más tarde.';
      case 'manualReview':
        return 'No hagas otro pago por ahora. Estamos revisando la operación.';
      default:
        return null;
    }
  }

  /// Pasos del flujo de confirmación (review screen).
  static const reservationConfirmationSteps = [
    'Elegís horario.',
    'Pagás con Mercado Pago.',
    'Cuando el pago se aprueba, tu clase queda confirmada.',
    'Podés seguir el estado en Mis reservas.',
  ];

  /// Flujo alumno post-registro (onboarding progresivo).
  static const studentBookingFlowSteps = [
    'Buscá un instructor.',
    'Elegí día y horario.',
    'Pagá para confirmar.',
    'Revisá el estado en Mis reservas.',
  ];
}
