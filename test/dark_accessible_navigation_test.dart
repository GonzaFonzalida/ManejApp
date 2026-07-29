import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/design/app_bottom_nav.dart';
import 'package:manejapp/widgets/design/app_button.dart';

void main() {
  test('ManejApp usa únicamente el tema oscuro', () {
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
    expect(AppTheme.darkTheme.scaffoldBackgroundColor, AppColors.background);
  });

  testWidgets(
    'la navegación compartida conserva etiquetas y áreas táctiles con texto grande',
    (tester) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: AppBottomNav(
                currentIndex: selectedIndex,
                onTap: (index) => selectedIndex = index,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Reservas'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.bySemanticsLabel('Navegación principal'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Reservas'));
      expect(selectedIndex, 1);
    },
  );

  testWidgets('los botones principales admiten texto grande sin desbordarse',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: AppButton(
                text: 'Confirmar y continuar al pago',
                onPressed: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Confirmar y continuar al pago'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
