import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/models/payment_status_result.dart';

void main() {
  group('PaymentStatusResult', () {
    test('fromApiMap normaliza envelope backend', () {
      final result = PaymentStatusResult.fromApiMap({
        'status': 'pending',
        'bookingId': 42,
        'preferenceId': 'pref-1',
        'paymentId': 'mp-1',
        'marketplace': true,
      });

      expect(result.paymentStatus, 'pending');
      expect(result.bookingId, 42);
      expect(result.preferenceId, 'pref-1');
      expect(result.paymentId, 'mp-1');
      expect(result.marketplace, isTrue);
    });

    test('resolveState paid confirma', () {
      final result = PaymentStatusResult(paymentStatus: 'paid');
      expect(result.resolveState(), PaymentConfirmationState.confirmed);
    });

    test('resolveState CONFIRMED en reserva confirma', () {
      final result = PaymentStatusResult(paymentStatus: 'pending');
      expect(
        result.resolveState(reservationStatus: 'CONFIRMED'),
        PaymentConfirmationState.confirmed,
      );
    });

    test('resolveState pending', () {
      final result = PaymentStatusResult(paymentStatus: 'pending');
      expect(result.resolveState(), PaymentConfirmationState.pending);
    });

    test('resolveState failed/cancelled', () {
      expect(
        PaymentStatusResult(paymentStatus: 'failed').resolveState(),
        PaymentConfirmationState.failed,
      );
      expect(
        PaymentStatusResult(paymentStatus: 'cancelled').resolveState(),
        PaymentConfirmationState.failed,
      );
      expect(
        PaymentStatusResult(paymentStatus: 'pending')
            .resolveState(reservationStatus: 'CANCELLED'),
        PaymentConfirmationState.failed,
      );
    });

    test('resolveState manual_review', () {
      final result = PaymentStatusResult(paymentStatus: 'manual_review');
      expect(result.resolveState(), PaymentConfirmationState.manualReview);
    });
  });
}
