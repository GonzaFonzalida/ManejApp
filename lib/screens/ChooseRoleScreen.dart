import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

class AuthService {
  static Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  static Future<String?> getUserId() async {
    return await storage.read(key: 'user_id');
  }
}

class ChooseRoleScreen extends StatefulWidget {
  static const routeName = 'choose-role';
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String _selectedRole = 'STUDENT';
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  bool _isLoading = false;

  String? _token;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    setState(() => _isLoading = true);
    try {
      _token = await AuthService.getToken();
      final userIdString = await AuthService.getUserId();
      if (userIdString != null) {
        _userId = int.tryParse(userIdString);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos de autenticación: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  Future<void> _submitRole() async {
    // ✅ CAMBIO AQUÍ: La condición ahora solo verifica el _userId.
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando datos de usuario, por favor espere.')),
      );
      return;
    }

    if (_selectedRole == 'INSTRUCTOR' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == 'INSTRUCTOR') {
        // ⚠️ ADVERTENCIA: La llamada a la API no incluye el token.
        // Esto es solo para propósitos de prueba.
        await ApiService.createInstructor(
          _userId!,
          _licenseNumberController.text,
          int.parse(_experienceYearsController.text),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tu rol ha sido actualizado a ${_selectedRole.toLowerCase()}')),
        );
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null && _isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Text('Completa tu perfil',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 8),
              const Text('Elige tu rol',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              const Text('Selecciona el rol que mejor te describa. Esto nos ayudará a personalizar tu experiencia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(height: 40),

              _roleOption(
                role: 'INSTRUCTOR',
                title: 'Instructor',
                subtitle: 'Comparte tu experiencia y gana enseñando a otros.',
                icon: Icons.school,
              ),
              const SizedBox(height: 16),

              _roleOption(
                role: 'STUDENT',
                title: 'Estudiante',
                subtitle: 'Aprende nuevas habilidades y expande tus conocimientos.',
                icon: Icons.person,
              ),

              const SizedBox(height: 24),

              if (_selectedRole == 'INSTRUCTOR')
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _licenseNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Licencia',
                          prefixIcon: Icon(Icons.credit_card),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Ingrese el número de licencia' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _experienceYearsController,
                        decoration: const InputDecoration(
                          labelText: 'Años de Experiencia',
                          prefixIcon: Icon(Icons.emoji_events),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingrese los años de experiencia';
                          if (int.tryParse(value) == null) return 'Ingrese un número válido';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRole,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continuar', style: TextStyle(fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleOption({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF2196F3) : Colors.black12, width: 2),
          boxShadow: [if (isSelected) BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: const Color(0xFFE3F2FD), child: Icon(icon, color: const Color(0xFF2196F3))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              ]),
            )
          ],
        ),
      ),
    );
  }
}
