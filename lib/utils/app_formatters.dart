import 'package:intl/intl.dart';

/// Formatos visibles compartidos para evitar que cada pantalla muestre
/// importes y fechas de una manera distinta.
abstract final class AppFormatters {
  static final NumberFormat _ars = NumberFormat.decimalPattern('es_AR')
    ..maximumFractionDigits = 0
    ..minimumFractionDigits = 0;

  static String ars(num value) => 'ARS ${_ars.format(value)}';

  static String shortDate(DateTime value) =>
      DateFormat('d MMM', 'es').format(value);

  static String dateAndTime(DateTime value) =>
      DateFormat('d MMM · HH:mm', 'es').format(value);

  static String timeRange(DateTime start, DateTime end) =>
      '${DateFormat('HH:mm').format(start)}–${DateFormat('HH:mm').format(end)}';
}
