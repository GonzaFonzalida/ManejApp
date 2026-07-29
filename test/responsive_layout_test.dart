// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/screens/payment_screen.dart';
import 'package:manejapp/screens/forgot_password_screen.dart';
import 'package:manejapp/screens/map_screen.dart';
import 'package:manejapp/models/instructor.dart';
import 'package:manejapp/screens/instructor_profile_screen.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';

Instructor _sampleInstructor() {
  return Instructor(
    id: 1,
    experienceYears: 5,
    hourlyRate: 12000,
    user: User(id: 1, name: 'Ana', surname: 'García'),
    bio: 'Instructora con experiencia en zona norte.',
  );
}

void main() {
  group('ResponsiveLayout', () {
    testWidgets('embeddedMapHeight clamps on short viewport', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      double? mapHeight;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              mapHeight = ResponsiveLayout.embeddedMapHeight(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(mapHeight, isNotNull);
      expect(mapHeight!, greaterThanOrEqualTo(160));
      expect(mapHeight!, lessThanOrEqualTo(320));
      expect(mapHeight!, lessThan(420));
    });

    testWidgets('heroIconSize shrinks on short viewport', (tester) async {
      double? iconSize;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(360, 480)),
            child: Builder(
              builder: (context) {
                iconSize = ResponsiveLayout.heroIconSize(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(iconSize, 120);
    });

    testWidgets('exploreSheetSizes increases initial size on short viewport',
        (tester) async {
      double? initial;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(360, 520)),
            child: Builder(
              builder: (context) {
                initial = ResponsiveLayout.exploreSheetSizes(context).initial;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(initial, greaterThan(0.38));
    });

    testWidgets('instructorProfileLayout shrinks map on short viewport',
        (tester) async {
      double? mapFraction;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(360, 520)),
            child: Builder(
              builder: (context) {
                mapFraction = ResponsiveLayout.instructorProfileLayout(context)
                    .mapFraction;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(mapFraction, lessThan(0.34));
    });

    testWidgets('scrollPadding grows with large text scale', (tester) async {
      EdgeInsets? normal;
      EdgeInsets? large;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              normal = ResponsiveLayout.scrollPadding(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: Builder(
              builder: (context) {
                large = ResponsiveLayout.scrollPadding(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(large!.bottom, greaterThan(normal!.bottom));
    });
  });

  group('ResponsiveScrollBody screens', () {
    testWidgets('PaymentScreen renders CTAs on small Android viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PaymentScreen(
            drivingClassId: 1,
            amount: 5000,
            description: 'Clase de manejo',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pagar con Mercado Pago'), findsOneWidget);
      expect(find.text('Consultar estado'), findsOneWidget);
      expect(find.byType(Scrollable), findsWidgets);
    });

    testWidgets('ForgotPasswordScreen stays scrollable with keyboard',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: ForgotPasswordScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Enviar enlace'), findsOneWidget);
      expect(find.byType(Scrollable), findsWidgets);
    });

    testWidgets(
        'MapScreen keeps search field inside SafeArea on small viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const MaterialApp(home: MapScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Mapa de ManejApp'), findsOneWidget);
    });

    testWidgets('InstructorProfileScreen keeps reserve CTA on small viewport',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: InstructorProfileScreen(instructor: _sampleInstructor()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reservar clase'), findsOneWidget);
      expect(find.byType(Scrollable), findsWidgets);
    });
  });
}
