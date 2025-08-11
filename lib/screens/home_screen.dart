import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  // Define la constante de la ruta para ser usada en la navegación
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Esta línea remueve la flecha para volver atrás del AppBar
        automaticallyImplyLeading: false,
        title: const Text('ManejApp - Inicio'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          '¡Bienvenido a la pantalla de inicio!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
