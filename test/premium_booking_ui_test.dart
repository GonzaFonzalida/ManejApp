import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/config/premium_booking_ui.dart';

void main() {
  test('PremiumBookingUi etiquetas coherentes', () {
    expect(PremiumBookingUi.statusLabel('CONFIRMED'), 'Confirmada');
    expect(PremiumBookingUi.statusChipLabel('CONFIRMED'), 'Confirmada');
    expect(PremiumBookingUi.paymentShortLabel('paid'), 'Pagado');
    expect(PremiumBookingUi.paymentShortLabel('manual_review'),
        'Pago en revisión');
    expect(
      PremiumBookingUi.paymentDetailNote('manual_review'),
      'No requiere acción por ahora',
    );
    expect(
      PremiumBookingUi.instructorReservationNeedsAttention(
        status: 'CONFIRMED',
        paymentStatus: 'manual_review',
      ),
      isTrue,
    );
    expect(
      PremiumBookingUi.instructorUpcomingSortKey(
        status: 'CONFIRMED',
        paymentStatus: 'manual_review',
      ),
      lessThan(
        PremiumBookingUi.instructorUpcomingSortKey(
          status: 'PENDING_PAYMENT',
          paymentStatus: 'pending',
        ),
      ),
    );
    expect(
      PremiumBookingUi.nextActionStudentCard('COMPLETE_PAYMENT'),
      contains('pago'),
    );
    expect(
      PremiumBookingUi.nextActionInstructorCard(
          'WAIT_FOR_PAYMENT_CONFIRMATION'),
      contains('alumno'),
    );
    expect(PremiumBookingUi.slotStatusLabel('BOOKED'), 'Reservado');
    expect(
      PremiumBookingUi.nextActionStudentCard('CHECK_RESERVATION_STATUS'),
      contains('estado'),
    );
    expect(
      PremiumBookingUi.whatsappUnavailableExplanation(
        'RESERVATION_NOT_CONFIRMED',
      ),
      contains('confirmada'),
    );
    expect(
      PremiumBookingUi.whatsappUnavailableExplanation('MISSING_PHONE_NUMBER'),
      contains('WhatsApp válido'),
    );
    expect(
      PremiumBookingUi.cancelUnavailableExplanation(status: 'COMPLETED'),
      contains('completada'),
    );
  });
}
