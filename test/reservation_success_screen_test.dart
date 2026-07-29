import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import 'package:manejapp/models/payment_status_result.dart';
import 'package:manejapp/screens/reservation_success_screen.dart';

Map<String, dynamic> _sampleReservation() => {
      'status': 'PENDING_PAYMENT',
      'paymentStatus': 'pending',
      'nextRecommendedAction': 'COMPLETE_PAYMENT',
      'startsAt': '2099-07-01T10:00:00.000Z',
      'policySummary': {'text': 'Política de prueba'},
      'cancelDeadline': '2099-06-30T10:00:00.000Z',
    };

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

ReservationSuccessScreen _screen({
  required PaymentStatusFetcher fetcher,
}) {
  return ReservationSuccessScreen(
    reservationId: 42,
    reservation: _sampleReservation(),
    paymentOpened: true,
    statusFetcher: fetcher,
    autoPoll: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  group('ReservationSuccessScreen polling UI', () {
    testWidgets('muestra confirmando inicialmente', (tester) async {
      final completer = Completer<PaymentStatusResult>();
      await tester.pumpWidget(_wrap(_screen(fetcher: (_) => completer.future)));
      await tester.pump();

      expect(find.text('Estamos confirmando tu pago…'), findsOneWidget);
      completer.complete(const PaymentStatusResult(paymentStatus: 'pending'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('paid muestra confirmado', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _screen(
            fetcher: (_) async =>
                const PaymentStatusResult(paymentStatus: 'paid'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tu reserva fue confirmada'), findsOneWidget);
      expect(find.text('Ver mis reservas'), findsOneWidget);
      expect(find.text('Ver detalle'), findsOneWidget);
    });

    testWidgets('pending tras consulta muestra pendiente', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _screen(
            fetcher: (_) async =>
                const PaymentStatusResult(paymentStatus: 'pending'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Pago pendiente de confirmación'), findsOneWidget);
      expect(find.text('Actualizar estado'), findsOneWidget);
      expect(find.textContaining('Te avisaremos'), findsNothing);
      expect(
        find.textContaining('Podés actualizar el estado desde esta pantalla'),
        findsOneWidget,
      );
    });

    testWidgets('failed muestra pago no confirmado', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _screen(
            fetcher: (_) async =>
                const PaymentStatusResult(paymentStatus: 'failed'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('El pago no se pudo confirmar'), findsOneWidget);
      expect(find.text('Intentar de nuevo'), findsOneWidget);
    });

    testWidgets('manual_review muestra revisión', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _screen(
            fetcher: (_) async =>
                const PaymentStatusResult(paymentStatus: 'manual_review'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('revisarlo manualmente'), findsOneWidget);
      expect(find.text('Ver mis reservas'), findsOneWidget);
    });

    testWidgets('botón actualizar vuelve a consultar', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _wrap(
          _screen(
            fetcher: (_) async {
              calls += 1;
              return const PaymentStatusResult(paymentStatus: 'pending');
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final initialCalls = calls;

      await tester.tap(find.byKey(E2eKeys.reservationSuccessRefreshStatus));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(calls, greaterThan(initialCalls));
    });
  });
}
