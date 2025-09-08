import 'package:flutter/material.dart';
import 'package:manejapp/screens/sub_screens/about_app_screen.dart';
import 'package:manejapp/screens/sub_screens/contact_screen.dart';
import 'package:manejapp/screens/sub_screens/first_steps_screen.dart';
import 'package:manejapp/screens/sub_screens/offers_screen.dart';
import 'package:manejapp/screens/sub_screens/settings_screen.dart';
import 'package:manejapp/screens/sub_screens/top_instructors_screen.dart';

class InfoScreen extends StatelessWidget {
  static const routeName = '/info';
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            // Fila de botones superior
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildInfoButton(
                  context,
                  icon: Icons.map_outlined,
                  iconColor: Colors.green,
                  title: 'Primeros pasos',
                  description: 'Aprende a usar la aplicación y agenda tus primeros entrenamientos.',
                  route: FirstStepsScreen.routeName,
                ),
                _buildInfoButton(
                  context,
                  icon: Icons.person,
                  iconColor: Colors.blue.shade900,
                  title: 'Instructores Mejor Calificados',
                  description: 'Los instructores que recibieron las calificaciones más altas.',
                  route: TopInstructorsScreen.routeName,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Fila de botones central
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildInfoButton(
                  context,
                  icon: Icons.contact_mail_outlined,
                  iconColor: Colors.orange,
                  title: 'Contacto',
                  description: 'Ponte en contacto con nosotros para resolver tus dudas.',
                  route: ContactScreen.routeName,
                ),
                _buildInfoButton(
                  context,
                  icon: Icons.local_offer_outlined,
                  iconColor: Colors.red,
                  title: 'Ofertas',
                  description: 'Revisa las ofertas para entrenamientos individuales.',
                  route: OffersScreen.routeName,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Fila de botones inferior
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildInfoButton(
                  context,
                  icon: Icons.settings,
                  iconColor: Colors.grey,
                  title: 'Configuración',
                  description: 'Gestiona tus datos, forma de pago, entre otros.',
                  route: SettingsScreen.routeName,
                ),
                _buildInfoButton(
                  context,
                  icon: Icons.directions_car,
                  iconColor: Colors.blue.shade900,
                  title: 'Sobre ManejApp',
                  description: 'Más información sobre el diseño y propósito de ManejApp.',
                  route: AboutAppScreen.routeName,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoButton(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String route,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4,
      height: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2.0,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}