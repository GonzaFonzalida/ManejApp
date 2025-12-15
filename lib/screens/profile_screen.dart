import 'package:flutter/material.dart';
import 'editar_perfil_screen.dart';
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

  Map<String, dynamic>? _profile;
  String? _profileImageUrl;
  int _imageTimestamp = DateTime.now().millisecondsSinceEpoch;
  String? _instructorDescription;
  double? _hourlyRate;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = await storage.read(key: 'user_id');
    if (userId != null) {
      final profile = await ApiService.getUserProfile(userId);
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _profileImageUrl = profile['profileImageUrl'] as String?;
          _imageTimestamp = DateTime.now().millisecondsSinceEpoch;
          _hourlyRate = profile['hourlyRate'] as double?;
        });
      }
      
      if (profile['role'] == 'INSTRUCTOR') {
        try {
          final instructors = await ApiService.getInstructors();
          final instructor = instructors.firstWhere(
            (i) => i['userId'].toString() == userId,
            orElse: () => null,
          );
          if (instructor != null && mounted) {
            setState(() {
              _instructorDescription = instructor['description'] as String?;
            });
          }
        } catch (e) {
          debugPrint('Error: $e');
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cerrar sesión: $e')),
          );
        }
      }
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
            GestureDetector(
              onTap: () async {
                final result = await Navigator.pushNamed(context, EditarPerfilScreen.routeName);
                if (result == true && mounted) {
                  await _loadProfile();
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage('$_profileImageUrl?t=$_imageTimestamp')
                        : null,
                    child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                        ? Icon(Icons.person, size: 50, color: Colors.blue.shade600)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Toca para editar foto",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_profile?['firstName'] ?? _profile?['name'] ?? ''} ${_profile?['lastName'] ?? _profile?['surname'] ?? ''}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, EditarPerfilScreen.routeName);
                if (result == true && mounted) {
                  await _loadProfile();
                }
              },
              child: const Text("Editar Perfil"),
            ),
            const SizedBox(height: 20),

            _buildProfileItem(Icons.person, "Nombre completo", '${_profile?['firstName'] ?? _profile?['name'] ?? ''} ${_profile?['lastName'] ?? _profile?['surname'] ?? ''}'),
            _buildProfileItem(Icons.email, "Correo electrónico", _profile?['email'] ?? "usuario@email.com"),
            _buildProfileItem(Icons.calendar_today, "Fecha de nacimiento", _formatDate(_profile?['birthDate'])),
            _buildProfileItem(Icons.location_on, "Ubicación", _profile?['location'] ?? "No especificada"),
            if (_hourlyRate != null)
              _buildProfileItem(Icons.attach_money, "Tarifa por hora", "\$${_hourlyRate!.toStringAsFixed(0)}"),
            const SizedBox(height: 20),

            if (_instructorDescription != null && _instructorDescription!.isNotEmpty) ...[
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
              Text(
                _instructorDescription!,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                icon: const Icon(Icons.settings),
                label: const Text("Configuración"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003087),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Cerrar Sesión"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
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
