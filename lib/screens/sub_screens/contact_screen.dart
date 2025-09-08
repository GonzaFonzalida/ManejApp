import 'package:flutter/material.dart';

class ContactScreen extends StatelessWidget {
  static const routeName = '/info/contact';
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '¿Tienes alguna duda, comentario o sugerencia? ¡Estamos aquí para ayudarte!',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 20),
              Text(
                'Puedes contactarnos a través de los siguientes medios:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.email, color: Colors.blue),
                title: Text('Correo Electrónico'),
                subtitle: Text('soporte@manejapp.com'),
              ),
              ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Teléfono'),
                subtitle: Text('+54 11 9876-5432'),
              ),
              ListTile(
                leading: Icon(Icons.location_on, color: Colors.red),
                title: Text('Dirección'),
                subtitle: Text('Av. Falsa 123, Buenos Aires, Argentina'),
              ),
              SizedBox(height: 20),
              Text(
                'Nuestro equipo de soporte está disponible de lunes a viernes de 9:00 a 18:00.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}