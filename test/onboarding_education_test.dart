import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/screens/onboarding_screen.dart';
import 'package:manejapp/utils/reservation_status_education.dart';

void main() {
  group('OnboardingScreen copy V1', () {
    testWidgets('muestra 3 pantallas sin chat, push ni admin', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump();

      expect(find.text('Aprendé a manejar con instructores cerca tuyo'),
          findsOneWidget);
      expect(find.textContaining('chat'), findsNothing);
      expect(find.textContaining('push'), findsNothing);
      expect(find.textContaining('admin'), findsNothing);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Reservá y pagá con claridad'), findsOneWidget);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Seguí el estado desde la app'), findsOneWidget);
      expect(find.text('Empezar'), findsOneWidget);
    });
  });

  group('ReservationStatusEducation', () {
    test('no expone enums técnicos', () {
      final hints = [
        ReservationStatusEducation.contextualHint(
          status: 'PENDING_PAYMENT',
          paymentStatus: 'pending',
        ),
        ReservationStatusEducation.contextualHint(
          status: 'CONFIRMED',
          paymentStatus: 'paid',
        ),
        ReservationStatusEducation.studentDetailGuidance(
          status: 'CONFIRMED',
          paymentStatus: 'paid',
        ),
        ReservationStatusEducation.studentDetailGuidance(
          status: 'PENDING_PAYMENT',
          paymentStatus: 'pending',
        ),
        ReservationStatusEducation.studentDetailGuidance(
          status: 'CONFIRMED',
          paymentStatus: 'manual_review',
        ),
      ];
      for (final h in hints) {
        expect(h, isNotNull);
        expect(h!, isNot(contains('PENDING_PAYMENT')));
        expect(h, isNot(contains('manual_review')));
        expect(h, isNot(contains('CONFIRMED')));
      }
    });

    test('manual_review guía a no repagar', () {
      final hint = ReservationStatusEducation.studentDetailGuidance(
        status: 'PENDING_PAYMENT',
        paymentStatus: 'manual_review',
      );
      expect(hint, contains('No hagas otro pago'));
    });

    test('pasos de confirmación en review', () {
      expect(
        ReservationStatusEducation.reservationConfirmationSteps.length,
        4,
      );
      expect(
        ReservationStatusEducation.reservationConfirmationSteps.first,
        contains('horario'),
      );
    });
  });
}
