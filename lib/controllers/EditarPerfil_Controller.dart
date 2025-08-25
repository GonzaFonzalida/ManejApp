import 'package:flutter/material.dart';

class EditarPerfilController {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController zonaController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController disponibilidadController = TextEditingController();

  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    zonaController.dispose();
    precioController.dispose();
    disponibilidadController.dispose();
  }
}
