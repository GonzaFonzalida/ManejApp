import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/design/next_action_card.dart';

void main() {
  testWidgets(
    'la prioridad se integra al contenedor sin una barra lateral flotante',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.6),
            ),
            child: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: NextActionCard(
                  priority: NextActionPriority.high,
                  icon: Icons.upload_file_rounded,
                  title: 'Completá tu documentación',
                  description:
                      'Subí los cinco documentos obligatorios para continuar.',
                  primaryLabel: 'Subir documentos',
                  onPrimary: _noop,
                ),
              ),
            ),
          ),
        ),
      );

      final cardSurface = find.descendant(
        of: find.byType(NextActionCard),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container || widget.decoration is! BoxDecoration) {
            return false;
          }
          final decoration = widget.decoration! as BoxDecoration;
          return decoration.borderRadius ==
                  BorderRadius.circular(AppRadius.xl) &&
              decoration.border is Border;
        }),
      );

      expect(cardSurface, findsOneWidget);
      final card = tester.widget<Container>(cardSurface);
      final decoration = card.decoration! as BoxDecoration;
      final border = decoration.border! as Border;
      expect(border.left, border.top);
      expect(border.top, border.right);
      expect(border.right, border.bottom);

      final legacyRail = find.descendant(
        of: find.byType(NextActionCard),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.minWidth == 5 &&
              widget.constraints?.maxWidth == 5,
        ),
      );
      expect(legacyRail, findsNothing);
      expect(find.text('Subir documentos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

void _noop() {}
