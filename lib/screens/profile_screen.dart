import 'package:flutter/material.dart';
import 'EditarPerfil_Screen.dart';
import 'home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

const storage = FlutterSecureStorage();

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 2; // Profile is selected
  Map<String, dynamic>? _profile;
  String _selectedLocation = 'Tortuguitas';

  final List<String> _locations = [
    'Malvinas Argentinas',
    'Grand Bourg',
    'Los Polvorines',
    'Ingeniero Pablo Nogues',
    'Tortuguitas',
    'Villa de Mayo',
    'Tierras Altas',
    'Ing. Adolfo Sourdeaux',
    'Área de Promoción',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await storage.read(key: 'user_id');
    if (userId != null) {
      final profile = await ApiService.getUserProfile(userId);
      setState(() {
        _profile = profile;
        _selectedLocation = _profile?['location'] ?? 'Tortuguitas';
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0 || index == 1) { // Home or Map
      Navigator.pushNamed(context, HomeScreen.routeName);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile_placeholder.png'), // imagen genérica
            ),
            const SizedBox(height: 12),
            Text(
              _profile?['name'] ?? 'Nombre de Usuario',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, EditarPerfilScreen.routeName);
              },
              child: const Text("Editar Perfil"),
            ),
            const SizedBox(height: 20),

            // Información de perfil
            _buildProfileItem(Icons.person, "Nombre completo", _profile?['name'] ?? "Nombre de Usuario"),
            _buildProfileItem(Icons.email, "Correo electrónico", _profile?['email'] ?? "usuario@email.com"),
            _buildProfileItem(Icons.calendar_today, "Fecha de nacimiento", _formatDate(_profile?['birthDate'])),
            _buildLocationItem(Icons.location_on, "Vivo en", _selectedLocation),
            const SizedBox(height: 20),

            // Sobre mí
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    "Sobre mí",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Aquí irá la descripción del usuario. Puede actualizarla en Editar Perfil.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 30),

            // Botón cerrar sesión
            ElevatedButton(
              onPressed: () {
                // TODO: implementar logout
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text("Cerrar Sesión"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF003087),
        unselectedItemColor: Colors.grey.shade500,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                DropdownButton<String>(
                  value: value,
                  items: _locations.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLocation = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'dd/mm/aaaa';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d/M/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
