/// Estado de confirmación post-checkout derivado del pago y/o reserva.
enum PaymentConfirmationState {
  checking,
  confirmed,
  pending,
  failed,
  manualReview,
  networkError,
}

/// Respuesta normalizada de GET /payments/mercadopago/status/:identifier.
class PaymentStatusResult {
  final String paymentStatus;
  final String? bookingStatus;
  final int? bookingId;
  final String? preferenceId;
  final String? paymentId;
  final String? externalReference;
  final String? message;
  final bool marketplace;
  final Map<String, dynamic> raw;

  const PaymentStatusResult({
    required this.paymentStatus,
    this.bookingStatus,
    this.bookingId,
    this.preferenceId,
    this.paymentId,
    this.externalReference,
    this.message,
    this.marketplace = false,
    this.raw = const {},
  });

  factory PaymentStatusResult.fromApiMap(Map<String, dynamic> data) {
    final status = _firstNonEmpty([
      data['paymentStatus'],
      data['status'],
    ]);

    final booking = _firstNonEmpty([
      data['bookingStatus'],
      data['drivingClassStatus'],
      data['drivingClass']?['status'],
    ]);

    return PaymentStatusResult(
      paymentStatus: status.isEmpty ? 'pending' : status,
      bookingStatus: booking.isEmpty ? null : booking,
      bookingId: _asInt(data['bookingId'] ?? data['drivingClassId']),
      preferenceId: _asString(data['preferenceId']),
      paymentId: _asString(data['paymentId']),
      externalReference: _asString(data['externalReference']),
      message: _asString(data['message']),
      marketplace: data['marketplace'] == true,
      raw: Map<String, dynamic>.from(data),
    );
  }

  /// Combina estado de pago MP/DB con estado de reserva premium si está disponible.
  PaymentConfirmationState resolveState({String? reservationStatus}) {
    final pay = paymentStatus.toLowerCase().trim();
    final booking =
        (reservationStatus ?? bookingStatus ?? '').toUpperCase().trim();

    if (pay == 'manual_review') {
      return PaymentConfirmationState.manualReview;
    }

    if (pay == 'paid' || pay == 'approved' || booking == 'CONFIRMED') {
      return PaymentConfirmationState.confirmed;
    }

    if (pay == 'failed' ||
        pay == 'rejected' ||
        pay == 'cancelled' ||
        pay == 'canceled' ||
        pay == 'refunded' ||
        pay == 'charged_back' ||
        booking == 'CANCELLED') {
      return PaymentConfirmationState.failed;
    }

    if (pay == 'pending' ||
        pay == 'in_process' ||
        pay == 'in_mediation' ||
        booking == 'PENDING_PAYMENT') {
      return PaymentConfirmationState.pending;
    }

    return PaymentConfirmationState.pending;
  }

  bool get isFinal {
    final state = resolveState();
    return state != PaymentConfirmationState.checking &&
        state != PaymentConfirmationState.pending;
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

/// Resultado de crear preferencia MP para una reserva.
class BookingPaymentPreference {
  final String initPoint;
  final String? preferenceId;

  const BookingPaymentPreference({
    required this.initPoint,
    this.preferenceId,
  });
}
