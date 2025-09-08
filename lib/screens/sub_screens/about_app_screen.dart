import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  static const routeName = '/info/about_app';
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre ManejApp'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'ManejApp fue creada con la misión de democratizar el aprendizaje de manejo, conectando a estudiantes con instructores calificados de manera sencilla y segura.',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 20),
              Text(
                'Nuestra visión es eliminar las barreras de acceso a la educación vial y contribuir a la formación de conductores responsables y confiados en las calles. ',
              ),
              SizedBox(height: 20),
              Text(
                'Creemos firmemente que una buena educación al volante es la base para una conducción segura. Por eso, nos esforzamos en ofrecer una plataforma intuitiva, transparente y confiable para todos.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}