import 'package:flutter/material.dart';

class ReservarClaseController {
  final ValueNotifier<int> fechaSeleccionada = ValueNotifier<int>(0);
  final ValueNotifier<String?> horaSeleccionada = ValueNotifier<String?>(null);

  final List<String> fechas = ["Lun 1", "Mar 2", "Mié 3", "Jue 4", "Vie 5"];
  final List<String> horarios = ["15:00", "16:00", "18:00", "19:00"];

  void seleccionarFecha(int index) {
    fechaSeleccionada.value = index;
  }

  void seleccionarHora(String hora) {
    horaSeleccionada.value = hora;
  }
}
 