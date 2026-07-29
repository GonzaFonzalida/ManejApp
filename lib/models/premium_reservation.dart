import 'package:manejapp/config/premium_booking_ui.dart';

class PremiumReservation {
  final Map<String, dynamic> raw;

  PremiumReservation(this.raw);

  int get id => (raw['id'] as num).toInt();
  String get status => (raw['status'] ?? '').toString();
  String? get cancellationReason {
    final value = raw['cancellationReason'] ?? raw['cancellation_reason'];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String get paymentStatus => (raw['paymentStatus'] ?? '').toString();
  String get slotStatus => (raw['slotStatus'] ?? '').toString();
  bool get canCancel => raw['canCancel'] == true;
  bool get canReschedule => raw['canReschedule'] == true;
  Map<String, dynamic> get _whatsappContact {
    final value = raw['whatsappContact'];
    return value is Map<String, dynamic> ? value : const <String, dynamic>{};
  }

  bool get whatsappEnabled => _whatsappContact['enabled'] == true;
  String? get whatsappLaunchUrl {
    final value = _whatsappContact['launchUrl']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get whatsappPhoneNumber {
    final value = _whatsappContact['phoneNumber']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get whatsappCounterpartName {
    final value = _whatsappContact['counterpartName']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? get whatsappUnavailableReason =>
      _whatsappContact['unavailableReason']?.toString();
  String get nextRecommendedAction =>
      (raw['nextRecommendedAction'] ?? 'NO_ACTION').toString();
  int get durationMinutes => ((raw['durationMinutes'] as num?) ?? 0).toInt();

  DateTime? get startsAt {
    final value = raw['startsAt']?.toString();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  DateTime? get endsAt {
    final value = raw['endsAt']?.toString();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  DateTime? get cancelDeadline {
    final value = raw['cancelDeadline']?.toString();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  DateTime? get rescheduleDeadline {
    final value = raw['rescheduleDeadline']?.toString();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String get policyText =>
      raw['policySummary']?['text']?.toString() ?? 'Política no disponible';

  String get priceLabel =>
      raw['priceSummary']?['estimatedTotalLabel']?.toString() ??
      'Monto no disponible';

  String get instructorName {
    final name = raw['instructorSnapshot']?['name']?.toString() ?? '';
    final surname = raw['instructorSnapshot']?['surname']?.toString() ?? '';
    final full = '$name $surname'.trim();
    return full.isEmpty ? 'Instructor' : full;
  }

  int? get instructorId {
    final v =
        raw['instructorSnapshot']?['id'] ?? raw['legacy']?['instructorId'];
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  String get locationLabel =>
      raw['location']?['zoneLabel']?.toString() ??
      raw['location']?['addressText']?.toString() ??
      'Ubicación a confirmar';

  /// Vista instructor: alumno asignado a la reserva.
  String get studentName {
    final name = raw['studentSnapshot']?['name']?.toString() ?? '';
    final surname = raw['studentSnapshot']?['surname']?.toString() ?? '';
    final full = '$name $surname'.trim();
    return full.isEmpty ? 'Alumno' : full;
  }

  int? get studentExperienceLevel {
    final v = raw['studentSnapshot']?['experienceLevel'];
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Texto corto para cards (rol instructor).
  String get nextActionHintInstructor =>
      PremiumBookingUi.nextActionInstructorCard(nextRecommendedAction);

  /// Texto corto para cards (rol alumno).
  String get nextActionHintStudent =>
      PremiumBookingUi.nextActionStudentCard(nextRecommendedAction);
}
