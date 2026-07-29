import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/models/premium_reservation.dart';
import 'package:manejapp/utils/whatsapp.dart';
import 'package:manejapp/widgets/design/app_button.dart';

void main() {
  group('WhatsApp', () {
    test('normaliza solo números internacionales válidos', () {
      expect(
        normalizeWhatsAppNumber('+54 9 11 2233-4455'),
        '+5491122334455',
      );
      expect(normalizeWhatsAppNumber('11 2233-4455'), isNull);
      expect(validateWhatsAppNumber('+123'), isNotNull);
    });

    test('lee el contacto habilitado de una reserva confirmada', () {
      final reservation = PremiumReservation({
        'id': 8,
        'status': 'CONFIRMED',
        'whatsappContact': {
          'enabled': true,
          'counterpartName': 'Ana Pérez',
          'phoneNumber': '+5491122334455',
          'launchUrl': 'https://wa.me/5491122334455?text=Hola',
          'unavailableReason': null,
        },
      });

      expect(reservation.whatsappEnabled, isTrue);
      expect(reservation.whatsappCounterpartName, 'Ana Pérez');
      expect(reservation.whatsappPhoneNumber, '+5491122334455');
      expect(reservation.whatsappLaunchUrl, startsWith('https://wa.me/'));
    });

    test('no inventa contacto para respuestas antiguas o no confirmadas', () {
      final reservation = PremiumReservation({
        'id': 9,
        'status': 'PENDING_PAYMENT',
      });
      expect(reservation.whatsappEnabled, isFalse);
      expect(reservation.whatsappLaunchUrl, isNull);
    });

    testWidgets('el CTA de WhatsApp usa el verde de marca', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Escribir por WhatsApp',
              icon: Icons.chat_rounded,
              onPressed: () {},
              type: AppButtonType.whatsapp,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        button.style?.backgroundColor?.resolve(<WidgetState>{}),
        AppColors.whatsapp,
      );
    });
  });
}
