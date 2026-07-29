import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/controllers/reservar_clase_controller.dart';

void main() {
  group('ReservarClaseController', () {
    test('expone 7 fechas y horarios fijos', () {
      final c = ReservarClaseController();
      expect(c.apiFechas.length, 7);
      expect(c.displayFechas.length, 7);
      expect(c.horarios, contains('15:00'));
    });

    test('seleccionarFecha ignora índice fuera de rango', () {
      final c = ReservarClaseController();
      final initial = c.fechaSeleccionada.value;
      c.seleccionarFecha(-1);
      expect(c.fechaSeleccionada.value, initial);
      c.seleccionarFecha(99);
      expect(c.fechaSeleccionada.value, initial);
    });

    test('seleccionarFecha y hora actualizan estado', () {
      final c = ReservarClaseController();
      c.seleccionarFecha(2);
      expect(c.fechaSeleccionada.value, 2);
      expect(c.selectedApiDate, c.apiFechas[2]);

      c.seleccionarHora('16:00');
      expect(c.horaSeleccionada.value, '16:00');
    });
  });
}
