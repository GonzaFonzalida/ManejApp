import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/utils/cancellation_reason_copy.dart';

void main() {
  group('humanizeCancellationReason', () {
    test('mapea motivos conocidos', () {
      expect(
        humanizeCancellationReason('HOLD_EXPIRED'),
        'La reserva se canceló porque el tiempo para completar el pago expiró.',
      );
      expect(
        humanizeCancellationReason('payment_failed'),
        'El pago no pudo confirmarse.',
      );
      expect(
        humanizeCancellationReason('STUDENT_CANCELLED'),
        'Cancelaste esta reserva.',
      );
      expect(
        humanizeCancellationReason('INSTRUCTOR_CANCELLED'),
        'El instructor canceló esta reserva.',
      );
      expect(
        humanizeCancellationReason('ADMIN_CANCELLED'),
        'La reserva fue cancelada por soporte.',
      );
      expect(
        humanizeCancellationReason('PAYMENT_CONFLICT'),
        'Hubo un problema con el pago. Estamos revisándolo.',
      );
    });

    test('fallback seguro para null, vacío y desconocido', () {
      const fallback = 'La reserva fue cancelada.';
      expect(humanizeCancellationReason(null), fallback);
      expect(humanizeCancellationReason(''), fallback);
      expect(humanizeCancellationReason('SYSTEM_CANCELLED'), fallback);
      expect(humanizeCancellationReason('UNKNOWN'), fallback);
      expect(humanizeCancellationReason('SOME_NEW_CODE'), fallback);
    });
  });

  group('humanizeCancellationReasonForInstructor', () {
    test('mapea motivos con copy del instructor', () {
      expect(
        humanizeCancellationReasonForInstructor('HOLD_EXPIRED'),
        'La reserva se canceló porque el alumno no completó el pago a tiempo.',
      );
      expect(
        humanizeCancellationReasonForInstructor('STUDENT_CANCELLED'),
        'El alumno canceló esta reserva.',
      );
      expect(
        humanizeCancellationReasonForInstructor('INSTRUCTOR_CANCELLED'),
        'Cancelaste esta reserva.',
      );
      expect(
        humanizeCancellationReasonForInstructor('PAYMENT_CONFLICT'),
        'Hubo un problema con el pago. Soporte lo está revisando.',
      );
    });
  });
}
