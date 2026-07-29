import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReservarClaseController {
  final ValueNotifier<int> fechaSeleccionada = ValueNotifier<int>(0);
  final ValueNotifier<String?> horaSeleccionada = ValueNotifier<String?>(null);

  late final List<String> displayFechas;
  late final List<String> apiFechas;
  final List<String> horarios = ["15:00", "16:00", "18:00", "19:00"];

  ReservarClaseController() {
    final now = DateTime.now();
    displayFechas = [];
    apiFechas = [];
    for (int i = 0; i < 7; i++) {
      final d = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1))
          .add(Duration(days: i));
      // Texto para mostrar (no depende del backend)
      displayFechas.add(DateFormat('EEE d').format(d));
      // Formato esperado por el backend
      apiFechas.add(DateFormat('yyyy-MM-dd').format(d));
    }
  }

  void seleccionarFecha(int index) {
    if (index >= 0 && index < apiFechas.length) {
      fechaSeleccionada.value = index;
    }
  }

  void seleccionarHora(String hora) {
    horaSeleccionada.value = hora;
  }

  String get selectedApiDate => apiFechas[fechaSeleccionada.value];
  String get selectedDisplayDate => displayFechas[fechaSeleccionada.value];
}
