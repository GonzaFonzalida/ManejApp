import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart'; // Importamos LoginScreen
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

class ChooseRoleScreen extends StatefulWidget {
  static const routeName = '/choose_role';
  final String userId;
  const ChooseRoleScreen({super.key, required this.userId});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String _selectedRole = 'Alumno';
  final _licenceController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _licenceController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submitRole() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('Intentando completar registro con userId: ${widget.userId}, role: $_selectedRole');
      debugPrint('Licence: ${_licenceController.text}, Experience: ${_experienceController.text}');
      await ApiService.completeRegistration(
        widget.userId,
        _selectedRole,
        licenceNumber: _selectedRole == 'Instructor' && _licenceController.text.isNotEmpty
            ? _licenceController.text
            : null,
        experienceYears: _selectedRole == 'Instructor' && _experienceController.text.isNotEmpty
            ? int.tryParse(_experienceController.text)
            : null,
      );

      // Limpiamos las credenciales temporales después del registro
      await storage.delete(key: 'temp_email');
      await storage.delete(key: 'temp_password');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro completado exitoso, inicia sesión')),
      );
      Navigator.pushReplacementNamed(context, LoginScreen.routeName); // Navegamos a LoginScreen
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error en _submitRole: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al completar el registro: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Completa tu perfil',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige tu rol',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003087),
                ),
              ),
              const SizedBox(height: 40),
              _buildRoleCard(
                role: 'Instructor',
                description: 'Comparte tu experiencia enseñando.',
                icon: Icons.school,
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                role: 'Alumno',
                description: 'Aprende nuevas habilidades.',
                icon: Icons.person,
              ),
              if (_selectedRole == 'Instructor') ...[
                const SizedBox(height: 24),
                const Text('Información adicional',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _licenceController,
                  label: 'Número de Licencia',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _experienceController,
                  label: 'Años de Experiencia',
                  icon: Icons.emoji_events,
                  keyboardType: TextInputType.number,
                ),
              ],
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitRole,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003087),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Completar Registro',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF003087) : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF003087).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF003087),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003087),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF003087)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }
}