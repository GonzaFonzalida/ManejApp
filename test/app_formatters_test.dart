import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/utils/app_formatters.dart';

void main() {
  test('muestra importes ARS con formato argentino compartido', () {
    expect(AppFormatters.ars(45000), 'ARS 45.000');
    expect(AppFormatters.ars(22500.45), 'ARS 22.500');
  });

  test('muestra rangos horarios sin formatos diferentes por pantalla', () {
    final start = DateTime(2026, 7, 19, 14, 30);
    final end = DateTime(2026, 7, 19, 15, 30);
    expect(AppFormatters.timeRange(start, end), '14:30–15:30');
  });
}
