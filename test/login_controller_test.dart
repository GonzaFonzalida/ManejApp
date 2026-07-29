import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/controllers/login_controller.dart';
import 'package:manejapp/screens/home_screen.dart';
import 'package:manejapp/screens/login_screen.dart';
import 'package:manejapp/utils/role_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginScreen validación (FormState)', () {
    testWidgets('campos vacíos: validate() falla y muestra error de email',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      final formState = tester.state<FormState>(find.descendant(
        of: find.byType(LoginScreen),
        matching: find.byType(Form),
      ));

      expect(formState.validate(), isFalse);
      await tester.pump();

      expect(find.text('Ingresá tu correo electrónico'), findsOneWidget);
    });

    testWidgets('email inválido muestra mensaje', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'no-es-email');
      await tester.enterText(fields.at(1), '123456');

      final formState = tester.state<FormState>(find.descendant(
        of: find.byType(LoginScreen),
        matching: find.byType(Form),
      ));
      expect(formState.validate(), isFalse);
      await tester.pump();

      expect(find.text('Correo electrónico inválido'), findsOneWidget);
    });

    testWidgets('contraseña corta muestra validación', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'a@b.com');
      await tester.enterText(fields.at(1), '12345');

      final formState = tester.state<FormState>(find.descendant(
        of: find.byType(LoginScreen),
        matching: find.byType(Form),
      ));
      expect(formState.validate(), isFalse);
      await tester.pump();

      expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    });
  });

  group('LoginController', () {
    test('loadSavedCredentials con rememberMe carga email', () async {
      SharedPreferences.setMockInitialValues({
        'rememberMe': true,
        'remembered_email': 'saved@test.com',
      });

      final c = LoginController();
      var updated = false;
      await c.loadSavedCredentials(() => updated = true);

      expect(c.rememberMe, isTrue);
      expect(c.emailController.text, 'saved@test.com');
      expect(updated, isTrue);
    });
  });

  group('navigateAfterAuth', () {
    testWidgets('si falla RoleRouter no navega a /home', (tester) async {
      String? lastRoute;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await navigateAfterAuth(
                        context,
                        'test',
                        overrides: RoleRouterOverrides(
                          apiGetMe: () async =>
                              throw Exception('auth/me failed'),
                        ),
                      );
                    },
                    child: const Text('auth'),
                  ),
                ),
              );
            },
          ),
          routes: {
            HomeScreen.routeName: (_) {
              lastRoute = HomeScreen.routeName;
              return const Scaffold(body: Text('HOME'));
            },
            LoginScreen.routeName: (_) {
              lastRoute = LoginScreen.routeName;
              return const Scaffold(body: Text('LOGIN'));
            },
          },
        ),
      );

      await tester.tap(find.text('auth'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('HOME'), findsNothing);
      expect(lastRoute, isNot(HomeScreen.routeName));
      expect(
        find.textContaining('no pudimos verificar tu perfil'),
        findsOneWidget,
      );
    });
  });
}
