import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/screens/register_screen.dart';

void main() {
  testWidgets('el registro revela identidad y contacto después del acceso',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const RegisterScreen(),
      ),
    );

    expect(find.text('Creá tu cuenta'), findsOneWidget);
    expect(find.text('ETAPA 1 DE 3 · CUENTA · PASO 1 DE 2'), findsOneWidget);
    expect(find.text('DNI'), findsNothing);

    final accessFields = find.byType(TextFormField);
    await tester.enterText(accessFields.at(0), 'Juan');
    await tester.enterText(accessFields.at(1), 'Pérez');
    await tester.enterText(accessFields.at(2), 'juan@example.com');
    await tester.enterText(accessFields.at(3), 'Manejapp123');
    final continueButton = find.widgetWithText(ElevatedButton, 'Continuar');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Completá tus datos'), findsOneWidget);
    expect(find.text('ETAPA 1 DE 3 · CUENTA · PASO 2 DE 2'), findsOneWidget);
    expect(find.text('DNI'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}
