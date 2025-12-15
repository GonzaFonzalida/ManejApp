import 'package:flutter/material.dart';
import '../controllers/editar_perfil_controller.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

const storage = FlutterSecureStorage();

class EditarPerfilScreen extends StatefulWidget {
  static var routeName = '/editarPerfil';
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final EditarPerfilController controller = EditarPerfilController();
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isInstructor = false;
  List<Map<String, String>> _locationSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    debugPrint('=== LOADING PROFILE ===');
    String? userId = await storage.read(key: 'user_id');
    debugPrint('userId from storage: $userId');
    
    if (userId == null || userId.isEmpty) {
      final token = await storage.read(key: 'auth_token');
      if (token != null && token.contains('.')) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = payload.padRight((payload.length + 3) & ~3, '=');
            final decoded = utf8.decode(base64.decode(normalized));
            final payloadData = jsonDecode(decoded) as Map<String, dynamic>;
            userId = payloadData['id']?.toString() ??
                payloadData['userId']?.toString() ??
                payloadData['sub']?.toString();
            if (userId != null) {
              await storage.write(key: 'user_id', value: userId);
            }
          }
        } catch (_) {}
      }
    }
    
    if (userId != null && userId.isNotEmpty) {
      try {
        debugPrint('Fetching profile from API...');
        final profile = await ApiService.getUserProfile(userId);
        debugPrint('Profile received: $profile');
        final isInstructor = profile['role'] == 'INSTRUCTOR';
        debugPrint('Is instructor: $isInstructor');
        
        if (mounted) {
          final fullImageUrl = profile['profileImageUrl'] as String?;
          final hourlyRateValue = profile['hourlyRate'];
          final hourlyRateStr = hourlyRateValue != null ? hourlyRateValue.toString() : '';
          setState(() {
            controller.nombreController.text = profile['name'] ?? '';
            controller.zonaController.text = profile['location'] ?? '';
            controller.precioController.text = hourlyRateStr;
            _currentImageUrl = fullImageUrl;
            _isInstructor = isInstructor;
          });
        }
        
        if (isInstructor) {
          try {
            debugPrint('Fetching instructor data...');
            final instructors = await ApiService.getInstructors();
            debugPrint('Instructors count: ${instructors.length}');
            final instructor = instructors.firstWhere(
              (i) => i['userId'].toString() == userId,
              orElse: () => null,
            );
            debugPrint('Instructor found: ${instructor != null}');
            if (instructor != null) {
              debugPrint('Instructor description: ${instructor['description']}');
              if (mounted) {
                setState(() {
                  controller.descripcionController.text = instructor['description'] ?? '';
                });
              }
            }
          } catch (e) {
            debugPrint('Error cargando instructor: $e');
          }
        }
      } catch (e) {
        debugPrint('Error cargando perfil: $e');
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } finally {
      _isPickingImage = false;
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
    setState(() => _isLoading = true);
    try {
      String? userId = await storage.read(key: 'user_id');
      
      if (userId == null || userId.isEmpty) {
        final token = await storage.read(key: 'auth_token');
        if (token != null && token.contains('.')) {
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalized = payload.padRight(
                (payload.length + 3) & ~3,
                '=',
              );
              final decoded = utf8.decode(base64.decode(normalized));
              final payloadData = jsonDecode(decoded) as Map<String, dynamic>;
              userId = payloadData['id']?.toString() ??
                  payloadData['userId']?.toString() ??
                  payloadData['sub']?.toString();
              if (userId != null) {
                await storage.write(key: 'user_id', value: userId);
              }
            }
          } catch (e) {
            debugPrint('Error extrayendo userId del token: $e');
          }
        }
      }
      
      if (userId == null || userId.isEmpty) {
        throw Exception('Sesión inválida. Por favor, inicia sesión nuevamente.');
      }

      final Map<String, dynamic> userData = {
        'name': controller.nombreController.text.trim(),
        'location': controller.zonaController.text.trim(),
      };
      
      if (_isInstructor && controller.precioController.text.isNotEmpty) {
        userData['hourlyRate'] = double.tryParse(controller.precioController.text.trim()) ?? 0.0;
      }

      if (_selectedImage != null) {
        await ApiService.uploadProfileImage(userId, _selectedImage!);
        if (mounted) {
          setState(() => _selectedImage = null);
        }
      }

      await ApiService.updateUser(userId, userData);
      
      if (_isInstructor) {
        try {
          final instructors = await ApiService.getInstructors();
          final instructor = instructors.firstWhere(
            (i) => i['userId'].toString() == userId,
            orElse: () => null,
          );
          if (instructor != null) {
            debugPrint('=== GUARDANDO INSTRUCTOR ====');
            debugPrint('instructorId: ${instructor['id']}');
            debugPrint('description: ${controller.descripcionController.text.trim()}');
            await ApiService.updateInstructor(instructor['id'].toString(), {
              'description': controller.descripcionController.text.trim(),
            });
            debugPrint('Instructor actualizado');
          }
        } catch (e) {
          debugPrint('Error actualizando instructor: $e');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Perfil actualizado exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Editar Perfil",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade400, Colors.blue.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _selectedImage != null
                            ? ClipOval(
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: 130,
                                  height: 130,
                                ),
                              )
                            : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _currentImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 130,
                                      height: 130,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('Error cargando imagen: $error');
                                        debugPrint('URL: $_currentImageUrl');
                                        return _buildDefaultAvatar();
                                      },
                                    ),
                                  )
                                : _buildDefaultAvatar(),
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
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 16, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        "Toca para cambiar foto",
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                _buildModernInputCard(
                  icon: Icons.person_outline,
                  label: "Nombre Completo",
                  child: TextField(
                    controller: controller.nombreController,
                    style: const TextStyle(fontSize: 16),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Ingresá tu nombre",
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildModernInputCard(
                  icon: Icons.location_on_outlined,
                  label: "Ubicación",
                  child: Column(
                    children: [
                      TextField(
                        controller: controller.zonaController,
                        style: const TextStyle(fontSize: 16),
                        onChanged: _searchLocations,
                        onTap: () => setState(() => _showSuggestions = true),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Ej: Tortuguitas, Buenos Aires",
                        ),
                      ),
                      if (_showSuggestions && _locationSuggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _locationSuggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _locationSuggestions[index];
                              return ListTile(
                                dense: true,
                                leading: Icon(Icons.location_on, size: 18, color: Colors.blue.shade600),
                                title: Text(
                                  suggestion['display']!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                onTap: () {
                                  controller.zonaController.text = suggestion['display']!;
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
                ),
                const SizedBox(height: 16),
                
                if (_isInstructor) ...[
                  _buildModernInputCard(
                    icon: Icons.attach_money,
                    label: "Tarifa por Hora",
                    child: TextField(
                      controller: controller.precioController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Ej: 5000",
                        prefix: Text("\$ "),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModernInputCard(
                    icon: Icons.edit_outlined,
                    label: "Descripción",
                    child: TextField(
                      controller: controller.descripcionController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Contá un poco sobre vos y tu experiencia...",
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Colors.blue.withValues(alpha: 0.4),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      "Guardar Cambios",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 60,
      color: Colors.white,
    );
  }

  Widget _buildModernInputCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}



