import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/info/settings';
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Desde esta sección puedes gestionar toda la información relacionada con tu cuenta y tu experiencia en ManejApp.',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 20),
              Text(
                '• Información de perfil: Actualiza tu nombre, foto, y preferencias.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '• Métodos de pago: Añade, edita o elimina tus tarjetas de crédito o débito para agendar clases fácilmente.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '• Notificaciones: Personaliza las alertas que deseas recibir sobre tus clases, ofertas especiales y más.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '• Seguridad y privacidad: Cambia tu contraseña y revisa las políticas de privacidad.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}