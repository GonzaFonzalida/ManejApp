import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/controllers/chat_controller.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import 'package:manejapp/screens/conversations_screen.dart';
import 'package:manejapp/screens/instructor_classes_screen.dart';
import 'package:manejapp/screens/reservation_success_screen.dart';
import 'package:manejapp/screens/student_classes_screen.dart';
import 'package:manejapp/screens/student_home_dashboard_screen.dart';
import 'package:manejapp/screens/student_dashboard_screen.dart';
import 'package:manejapp/screens/student_payments_screen.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:provider/provider.dart';

import 'support/premium_e2e_mock_server.dart';

/// Avanza el reloj de widgets por un tiempo acotado sin esperar que terminen
/// animaciones continuas (shimmer, loaders o indicadores del shell).
Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  const step = Duration(milliseconds: 100);
  final iterations = (duration.inMilliseconds / step.inMilliseconds).ceil();
  for (var i = 0; i < iterations; i++) {
    await tester.pump(step);
  }
}

/// E2E reservas premium (alumno + instructor) contra mock HTTP en loopback.
///
/// Un solo archivo evita lanzar dos veces la app macOS en la misma corrida (frágil).
///
/// `flutter test integration_test/premium_reservations_e2e_test.dart -d macos`
///
/// Cubre alumno: listado → detalle → cancelar → empty; éxito → Mis Reservas.
/// Cubre instructor: listado → detalle → CTA principal (recarga detalle).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late PremiumE2eMockServer server;

  setUpAll(() async {
    await initializeDateFormatting('es', null);
    server = await PremiumE2eMockServer.start();
  });

  tearDownAll(() async {
    await server.stop();
  });

  setUp(() {
    server.studentUpcomingEmpty = false;
    server.studentDetailCancelled = false;
    server.conversationsRespond500 = false;
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'e2e-token',
      'user_id': '7',
    });
  });

  testWidgets('alumno: Mis reservas → detalle → cancelar → listado vacío',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const StudentClassesScreen(),
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 4));

    expect(find.byKey(E2eKeys.studentReservationCard(1001)), findsOneWidget);

    await tester.tap(find.byKey(E2eKeys.studentReservationCard(1001)));
    await _pumpFor(tester, const Duration(seconds: 4));

    final studentWhatsApp =
        find.byKey(E2eKeys.studentReservationDetailWhatsapp);
    final studentPrimary = find.byKey(E2eKeys.studentReservationDetailPrimary);
    expect(studentWhatsApp, findsOneWidget);
    expect(find.text('Escribirle a Ana Pérez por WhatsApp'), findsOneWidget);
    expect(
        tester.widget<AppButton>(studentWhatsApp).type, AppButtonType.whatsapp);
    expect(
      tester.getTopLeft(studentWhatsApp).dy,
      lessThan(tester.getTopLeft(studentPrimary).dy),
    );
    expect(find.byKey(E2eKeys.studentReservationDetailCancel), findsOneWidget);

    await tester.tap(find.byKey(E2eKeys.studentReservationDetailCancel));
    await _pumpFor(tester, const Duration(seconds: 2));

    await tester.tap(find.byKey(E2eKeys.dialogConfirm));
    await _pumpFor(tester, const Duration(seconds: 4));

    expect(find.byKey(E2eKeys.studentReservationDetailWhatsapp), findsNothing);

    await tester.pageBack();
    await _pumpFor(tester, const Duration(seconds: 4));

    expect(find.byKey(E2eKeys.studentReservationsEmpty), findsOneWidget);
  });

  testWidgets('alumno: pantalla éxito → Ir a Mis Reservas', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ChatController()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          routes: {
            StudentDashboardScreen.routeName: (_) =>
                const StudentDashboardScreen(),
          },
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 600)),
            child: ReservationSuccessScreen(
              reservationId: 42,
              reservation: {
                'status': 'PENDING_PAYMENT',
                'paymentStatus': 'pending',
                'nextRecommendedAction': 'COMPLETE_PAYMENT',
                'startsAt': '2099-07-01T10:00:00.000Z',
                'policySummary': {
                  'text': 'Política de ejemplo para E2E.',
                },
                'cancelDeadline': '2099-06-30T10:00:00.000Z',
              },
              paymentOpened: false,
            ),
          ),
        ),
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 1));

    await tester.ensureVisible(find.byKey(E2eKeys.reservationSuccessGoToList));
    await tester.tap(find.byKey(E2eKeys.reservationSuccessGoToList));
    await _pumpFor(tester, const Duration(seconds: 2));

    expect(find.byType(StudentDashboardScreen), findsOneWidget);
  });

  testWidgets('alumno: Mis pagos carga resumen e importe desde mock',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'e2e-token',
      'user_id': '7',
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const StudentPaymentsScreen(),
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 5));

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.textContaining('2500'), findsWidgets);
    expect(find.text('Todos (1)'), findsOneWidget);
  });

  testWidgets(
      'alumno: home dashboard perfil completo sin reservas muestra CTA explorar',
      (tester) async {
    server.studentUpcomingEmpty = true;

    // Solo [StudentHomeDashboardScreen]: el shell con IndexedStack monta perfil/ajustes y suma providers.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: StudentHomeDashboardScreen(onSwitchTab: (_) {}),
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 8));

    expect(find.byKey(E2eKeys.studentHomeNoBookingsCard), findsOneWidget);
    expect(find.text('Todavía no reservaste'), findsOneWidget);
  });

  testWidgets('alumno: Mensajes lista vacía sin error', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ChatController(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const ConversationsScreen(),
        ),
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 6));

    expect(find.text('Todavía no tenés conversaciones'), findsOneWidget);
  });

  testWidgets('alumno: Mensajes error de red → Reintentar → lista vacía',
      (tester) async {
    server.conversationsRespond500 = true;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ChatController(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const ConversationsScreen(),
        ),
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 6));

    expect(find.text('No pudimos cargar tus conversaciones'), findsOneWidget);

    server.conversationsRespond500 = false;
    await tester.tap(find.byKey(E2eKeys.conversationsRetry));
    await _pumpFor(tester, const Duration(seconds: 6));

    expect(find.text('Todavía no tenés conversaciones'), findsOneWidget);
  });

  testWidgets('instructor: Mis clases → detalle → acción principal',
      (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'e2e-instructor',
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const InstructorClassesScreen(),
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 4));

    expect(find.byKey(E2eKeys.instructorReservationCard(2001)), findsOneWidget);

    await tester.tap(find.byKey(E2eKeys.instructorReservationCard(2001)));
    await _pumpFor(tester, const Duration(seconds: 4));

    final instructorWhatsApp =
        find.byKey(E2eKeys.instructorReservationDetailWhatsapp);
    final instructorPrimary =
        find.byKey(E2eKeys.instructorReservationDetailPrimary);
    expect(instructorWhatsApp, findsOneWidget);
    expect(find.text('Escribirle a Luis Gómez por WhatsApp'), findsOneWidget);
    expect(tester.widget<AppButton>(instructorWhatsApp).type,
        AppButtonType.whatsapp);
    expect(
      tester.getTopLeft(instructorWhatsApp).dy,
      lessThan(tester.getTopLeft(instructorPrimary).dy),
    );
    expect(
        find.byKey(E2eKeys.instructorReservationDetailPrimary), findsOneWidget);

    await tester.tap(find.byKey(E2eKeys.instructorReservationDetailPrimary));
    await _pumpFor(tester, const Duration(seconds: 3));

    expect(
        find.byKey(E2eKeys.instructorReservationDetailPrimary), findsOneWidget);
  });
}
