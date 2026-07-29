import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/design/app_avatar.dart';
import 'package:manejapp/widgets/design/app_availability_hint.dart';

void main() {
  testWidgets('avatar y explicación de disponibilidad son accesibles',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Column(
            children: [
              AppAvatar(name: 'Ana Pérez'),
              AppAvailabilityHint(
                message:
                    'WhatsApp se habilita cuando la reserva queda confirmada.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Foto de Ana Pérez'), findsOneWidget);
    expect(find.text('AP'), findsOneWidget);
    expect(
      find.text(
        'WhatsApp se habilita cuando la reserva queda confirmada.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
