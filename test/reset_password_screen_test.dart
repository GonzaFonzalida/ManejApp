import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/screens/reset_password_screen.dart';

void main() {
  testWidgets('muestra el flujo para crear una contraseña desde un enlace',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.darkTheme,
        home: const Scaffold(body: Text('Inicio')),
        routes: {
          ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
        },
      ),
    );

    navigatorKey.currentState!.pushNamed(
      ResetPasswordScreen.routeName,
      arguments: 'token-de-prueba',
    );
    await tester.pumpAndSettle();

    expect(find.text('Protegé tu cuenta'), findsOneWidget);
    expect(find.text('Contraseña nueva'), findsOneWidget);
    expect(find.text('Repetí la contraseña'), findsOneWidget);
    expect(find.text('Guardar contraseña'), findsOneWidget);
  });
}
