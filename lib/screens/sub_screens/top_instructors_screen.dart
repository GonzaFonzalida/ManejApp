import 'package:flutter/material.dart';

class TopInstructorsScreen extends StatelessWidget {
  static const routeName = '/info/top_instructors';
  const TopInstructorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instructores Mejor Calificados'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'La calificación de nuestros instructores se basa en las valoraciones de los estudiantes que han completado clases con ellos.',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 20),
              Text(
                'Factores clave que influyen en la calificación:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
              ),
              SizedBox(height: 10),
              Text(
                '• Experiencia: Número de años y diversidad de alumnos con los que han trabajado.',
              ),
              Text(
                '• Tasa de éxito: Porcentaje de estudiantes que superan el examen de conducir tras completar sus clases.',
              ),
              Text(
                '• Reseñas y comentarios: Opiniones directas de los estudiantes sobre la paciencia, metodología y profesionalismo del instructor.',
              ),
              Text(
                '• Puntualidad y fiabilidad: Cumplimiento de los horarios y compromiso con la clase.',
              ),
              SizedBox(height: 20),
              Text(
                'Nuestro objetivo es que encuentres un instructor que se adapte perfectamente a tu estilo de aprendizaje y te ayude a alcanzar tu meta de obtener tu licencia de conducir.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}