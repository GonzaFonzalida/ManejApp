import 'package:flutter/material.dart';

class OffersScreen extends StatelessWidget {
  static const routeName = '/info/offers';
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Descubre nuestras ofertas exclusivas y aprovecha al máximo tus clases de manejo.',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20),
              _buildOfferCard(
                title: 'Paquete de 5 Clases',
                price: '\$140,000',
                details: 'Aprende lo básico y toma confianza al volante con nuestro paquete inicial.',
              ),
              const SizedBox(height: 20),
              _buildOfferCard(
                title: 'Paquete Intensivo de 10 Clases',
                price: '\$220,500',
                details: 'Ideal para quienes quieren dominar la conducción en poco tiempo. Incluye prácticas en diferentes escenarios.',
              ),
              const SizedBox(height: 20),
              _buildOfferCard(
                title: 'Clase individual',
                price: '\$70,000/h',
                details: '¿Solo necesitas una clase de refuerzo? Agenda una clase individual con tu instructor favorito.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard({
    required String title,
    required String price,
    required String details,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
            const SizedBox(height: 5),
            Text(
              price,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 24.0, color: Colors.green),
            ),
            const SizedBox(height: 10),
            Text(details),
          ],
        ),
      ),
    );
  }
}