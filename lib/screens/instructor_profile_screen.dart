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
  final _locationController = TextEditingController();
  
  Map<String, dynamic>? _instructor;
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  String? _instructorId;
  String? _userId;
  List<Map<String, String>> _locationSuggestions = [];
  bool _showSuggestions = false;

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
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = await storage.read(key: 'user_id');
      if (userId != null) {
        _userId = userId;
        _user = await ApiService.getUserProfile(userId);
        
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
          _hourlyRateController.text = _user?['hourlyRate']?.toString() ?? '';
          _locationController.text = _user?['location'] ?? '';
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

  Future<void> _searchLocations(String query) async {
    if (query.length < 3) {
      if (mounted) {
        setState(() {
          _locationSuggestions = [];
          _showSuggestions = false;
        });
      }
      return;
    }

    try {
      final results = await ApiService.searchLocations(query);
      if (mounted) {
        setState(() {
          _locationSuggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationSuggestions = [];
          _showSuggestions = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      
      if (_userId != null) {
        await ApiService.updateUser(_userId!, {
          'location': _locationController.text.trim(),
          'hourlyRate': double.tryParse(_hourlyRateController.text) ?? 0.0,
        });
      }
      
      if (_instructorId != null) {
        await ApiService.updateInstructor(_instructorId!, {
          'licenseNumber': _licenseController.text,
          'experienceYears': int.tryParse(_experienceController.text) ?? 0,
          'description': _descriptionController.text,
        });
      }
        
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado exitosamente')),
        );
        setState(() => _isEditing = false);
        _loadProfile();
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

    if (confirm == true && mounted) {
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

                    Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.person, size: 60, color: Colors.blue.shade600),
                      ),
                    ),
                    const SizedBox(height: 24),

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
                              '${_instructor?['user']?['firstName'] ?? _user?['firstName'] ?? ''} ${_instructor?['user']?['lastName'] ?? _user?['lastName'] ?? ''}',
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _locationController,
                                  enabled: _isEditing,
                                  onChanged: _searchLocations,
                                  decoration: InputDecoration(
                                    labelText: 'Ubicación',
                                    prefixIcon: const Icon(Icons.location_on),
                                    hintText: 'Ej: Tortuguitas, Buenos Aires',
                                    border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
                                    filled: !_isEditing,
                                    fillColor: _isEditing ? null : Colors.grey.shade100,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingrese su ubicación';
                                    }
                                    return null;
                                  },
                                ),
                                if (_showSuggestions && _locationSuggestions.isNotEmpty && _isEditing)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _locationSuggestions.length,
                                      itemBuilder: (context, index) {
                                        final suggestion = _locationSuggestions[index];
                                        return ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.location_on, size: 18),
                                          title: Text(
                                            suggestion['display']!,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          onTap: () {
                                            _locationController.text = suggestion['display']!;
                                            setState(() {
                                              _showSuggestions = false;
                                              _locationSuggestions = [];
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                              ],
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

                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _isEditing = false);
                                _loadProfile();
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
