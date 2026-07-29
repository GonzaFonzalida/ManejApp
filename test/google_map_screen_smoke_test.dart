// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manejapp/screens/map_screen.dart';

/// Smoke: la pantalla de mapa usa [GoogleMap] (no OSM / placeholder).
void main() {
  testWidgets('MapScreen incluye widget GoogleMap',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));
    await tester.pump();
    expect(find.byType(GoogleMap), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(GoogleMap), findsOneWidget);
  });
}
