import 'package:flutter/material.dart';

class FirstStepsScreen extends StatelessWidget {
  static const routeName = '/info/first_steps';
  const FirstStepsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Primeros pasos'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Aprender a manejar es más fácil de lo que crees. ¡Sigue estos sencillos pasos para empezar!',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 20),
              Text(
                '1. Configura tu perfil:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              Text(
                'Completa tu perfil con tu información personal y preferencias para que podamos encontrar los mejores instructores para ti.',
              ),
              SizedBox(height: 10),
              Text(
                '2. Busca instructores cercanos:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              Text(
                'Utiliza el mapa en la pantalla de inicio para ver a los instructores disponibles en tu área. Puedes filtrar por tipo de vehículo o calificaciones.',
              ),
              SizedBox(height: 10),
              Text(
                '3. Agenda tu primera clase:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              Text(
                'Selecciona a tu instructor ideal y elige una fecha y hora que te convengan. Recibirás una confirmación instantánea.',
              ),
              SizedBox(height: 10),
              Text(
                '4. ¡Empieza a manejar!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              Text(
                'Tu instructor se pondrá en contacto contigo para coordinar el punto de encuentro. ¡No te preocupes, están ahí para ayudarte en cada paso del camino!',
              ),
            ],
          ),
        ),
      ),
    );
  }
}