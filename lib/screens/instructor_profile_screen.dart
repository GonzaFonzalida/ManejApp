import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../controllers/login_controller.dart';

const storage = FlutterSecureStorage();

class InstructorProfileScreen extends StatefulWidget {
  const InstructorProfileScreen({super.key});

  @override
  State<InstructorProfileScreen> createState() => _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  Map<String, dynamic>? _instructor;
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _instructorId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = await storage.read(key: 'user_id');
      if (userId != null) {
        // Obtener información del usuario
        _user = await ApiService.getUserProfile(userId);
        
        // Obtener información del instructor
        final instructors = await ApiService.getInstructors();
        _instructor = instructors.firstWhere(
          (i) => i['userId'].toString() == userId,
          orElse: () => null,
        );
        
        if (_instructor != null) {
          _instructorId = _instructor!['id'].toString();
          _licenseController.text = _instructor!['licenseNumber'] ?? '';
          _experienceController.text = _instructor!['experienceYears']?.toString() ?? '';
          _descriptionController.text = _instructor!['description'] ?? '';
          _hourlyRateController.text = _instructor!['hourlyRate']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      
      if (_instructorId != null) {
        await ApiService.updateInstructor(_instructorId!, {
          'licenseNumber': _licenseController.text,
          'experienceYears': int.tryParse(_experienceController.text) ?? 0,
          'description': _descriptionController.text,
          'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado exitosamente')),
          );
          setState(() => _isEditing = false);
          _loadProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      final loginController = LoginController();
      await loginController.logout(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Mi Perfil',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!_isEditing)
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003087),
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Foto de perfil
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _instructor?['image'] != null
                                ? NetworkImage(_instructor!['image'])
                                : const AssetImage('assets/car3.png') as ImageProvider,
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF003087),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    // TODO: Implementar cambio de foto
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Función de cambio de foto próximamente')),
                                    );
                                  },
                                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Información personal
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información Personal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoField(
                              'Nombre Completo',
                              '${_user?['name'] ?? ''} ${_user?['surname'] ?? ''}',
                              Icons.person,
                            ),
                            _buildInfoField(
                              'Email',
                              _user?['email'] ?? '',
                              Icons.email,
                            ),
                            _buildInfoField(
                              'Rol',
                              'Instructor',
                              Icons.school,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Información profesional
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información Profesional',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildEditableField(
                              'Número de Licencia',
                              _licenseController,
                              Icons.credit_card,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese el número de licencia';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildEditableField(
                              'Años de Experiencia',
                              _experienceController,
                              Icons.emoji_events,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese los años de experiencia';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Ingrese un número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildEditableField(
                              'Tarifa por Hora (\$)',
                              _hourlyRateController,
                              Icons.attach_money,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese la tarifa por hora';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Ingrese un número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildEditableField(
                              'Descripción',
                              _descriptionController,
                              Icons.description,
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingrese una descripción';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones de acción
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                                _loadProfile(); // Recargar datos originales
                              },
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003087),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Cerrar Sesión'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: _isEditing
            ? const OutlineInputBorder()
            : InputBorder.none,
        filled: !_isEditing,
        fillColor: _isEditing ? null : Colors.grey.shade100,
      ),
    );
  }
}