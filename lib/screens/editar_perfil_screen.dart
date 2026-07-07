import 'package:flutter/material.dart';
import '../controllers/editar_perfil_controller.dart';
import '../services/api_service.dart';
import 'package:manejapp/config/design_system.dart';
import '../services/secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manejapp/screens/instructor_dashboard_screen.dart';
import 'package:manejapp/screens/student_dashboard_screen.dart';
import 'package:manejapp/utils/role_router.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/services/location_autocomplete_controller.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/location_autocomplete_dropdown.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

const storage = appSecureStorage;

class EditarPerfilScreen extends StatefulWidget {
  static var routeName = '/editarPerfil';
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final EditarPerfilController controller = EditarPerfilController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;
  XFile? _selectedImage;
  String? _currentImageUrl;
  bool _isInstructor = false;
  final _locationAutocomplete = LocationAutocompleteController();
  String? _instructorId;
  String? _loadError;

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
      if (mounted) setState(() => _loadError = null);
      try {
        debugPrint('Fetching profile from API...');
        final profile = await ApiService.getUserProfile(userId);
        debugPrint('Profile received: $profile');
        final isInstructor = profile['role'] == 'INSTRUCTOR';
        debugPrint('Is instructor: $isInstructor');
        
        if (mounted) {
          final hourlyRateValue = profile['hourlyRate'];
          final hourlyRateStr = hourlyRateValue != null ? hourlyRateValue.toString() : '';
          setState(() {
            controller.nombreController.text = profile['name'] ?? '';
            controller.zonaController.text = profile['location'] ?? '';
            _phoneController.text = profile['phoneNumber'] ?? '';
            controller.precioController.text = hourlyRateStr;
            // Construir URL dinámicamente para evitar caché
            if (profile['profileImage'] != null) {
               _currentImageUrl = '${ApiService.baseUrl}/users/$userId/profile-image?t=${DateTime.now().millisecondsSinceEpoch}';
            } else {
               _currentImageUrl = null;
            }
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
              _instructorId = instructor['id'].toString();
              debugPrint('Instructor bio: ${instructor['bio']}');
                if (mounted) {
                  setState(() {
                    controller.descripcionController.text = instructor['bio'] ?? instructor['description'] ?? '';
                    final rate = instructor['hourlyRate'];
                    if (rate != null) {
                      controller.precioController.text = rate.toString();
                    }
                  });
                }
            }
          } catch (e) {
            debugPrint('Error cargando instructor: $e');
          }
        }
      } catch (e) {
        debugPrint('Error cargando perfil: $e');
        if (mounted) {
          setState(() {
            _loadError = humanizeApiError(e);
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      }
    }
  }

  @override
  void dispose() {
    _locationAutocomplete.dispose();
    controller.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        // En Web no podemos guardar en path local persistente del mismo modo que móviles
        // Pero usamos pickedFile directamente.
        if (kIsWeb) {
             if (mounted) {
               setState(() {
                 _selectedImage = pickedFile;
               });
             }
             // Subir inmediatamente en segundo plano
             _uploadImage(pickedFile);
        } else {
             // Móvil: Persistencia local para inmediatez en futuras sesiones
             // TODO: Implementar path provider si se requiere persistencia entre reinicios offline
             // Por ahora, comportamiento igual: set state inmediato y subida
             if (mounted) {
               setState(() {
                 _selectedImage = pickedFile;
               });
             }
             _uploadImage(pickedFile);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _uploadImage(XFile file) async {
      String? userId = await storage.read(key: 'user_id');
      if (userId == null) return;

      try {
        debugPrint('Subiendo imagen en segundo plano...');
        await ApiService.uploadProfileImage(userId, file);
        debugPrint('Imagen subida exitosamente');
        
        if (mounted) {
          // Actualizar URL remota para que la próxima vez que cargue de red, sea la nueva
          setState(() {
             _currentImageUrl = '${ApiService.baseUrl}/users/$userId/profile-image?t=${DateTime.now().millisecondsSinceEpoch}';
             // Opcional: Podríamos limpiar _selectedImage si quisiéramos volver a red, 
             // pero mejor dejar la local que es lo que el usuario acaba de elegir.
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto de perfil actualizada'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
          );
        }
      } catch (e) {
        debugPrint('Error subiendo imagen: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(humanizeApiError(e)), backgroundColor: Colors.orange),
          );
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
        if (userId == null || userId.isEmpty) return;
      }

      final Map<String, dynamic> userData = {
        'name': controller.nombreController.text.trim(),
        'location': controller.zonaController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
      };
      
      // Nota: La imagen ya se subió en _pickImage -> _uploadImage
      // Aquí solo guardamos datos de texto.

      await ApiService.updateUser(userId, userData);
      
      if (_isInstructor && _instructorId != null) {
        try {
            await ApiService.updateInstructor(_instructorId!, {
              'bio': controller.descripcionController.text.trim(),
              'hourlyRate': double.tryParse(controller.precioController.text.trim()) ?? 0.0,
            });
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
      
      final target = await RoleRouter.resolveRouteForCurrentUser(context: 'editar_perfil(afterSave)');
      if (!mounted) return;
      if (target == InstructorDashboardScreen.routeName) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          target,
          (route) => false,
          arguments: {'initialIndex': 3},
        );
      } else if (target == StudentDashboardScreen.routeName) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          target,
          (route) => false,
          arguments: {'initialIndex': 2},
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(target, (route) => false);
      }
    } catch (e) {
      debugPrint('Error guardando perfil: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanizeApiError(e)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surfaceLight,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Editar Perfil",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadError != null && _isInitialized
          ? SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: AppErrorState(
                    title: 'No pudimos cargar tu perfil',
                    message: _loadError,
                    onRetry: () {
                      setState(() => _loadError = null);
                      _loadProfile();
                    },
                  ),
                ),
              ),
            )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                children: [
                Semantics(
                  label: 'Cambiar foto de perfil',
                  button: true,
                  child: GestureDetector(
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
                        child: ClipOval(
                          child: _selectedImage != null
                              ? (kIsWeb 
                                  ? Image.network(_selectedImage!.path, fit: BoxFit.cover, width: 130, height: 130)
                                  : Image.file(File(_selectedImage!.path), fit: BoxFit.cover, width: 130, height: 130))
                              : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                  ? Image.network(
                                      _currentImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 130,
                                      height: 130,
                                      errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                                    )
                                  : _buildDefaultAvatar()),
                        ),
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
                ),
                // ... rest of UI code (Text "Toca para cambiar foto", inputs, etc. same as before)
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
                      style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Ingresá tu nombre",
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ),
                // ... (rest of fields unchanged)
                const SizedBox(height: 16),
                
                _buildModernInputCard(
                  icon: Icons.phone_outlined,
                  label: "Teléfono",
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Ej: 11 1234-5678",
                      hintStyle: TextStyle(color: AppColors.textSecondary),
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
                          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                          onChanged: _locationAutocomplete.onQueryChanged,
                          onTap: _locationAutocomplete.onFocus,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Ej: Tortuguitas, Buenos Aires",
                            hintStyle: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      AnimatedBuilder(
                        animation: _locationAutocomplete,
                        builder: (context, _) {
                          if (!_locationAutocomplete.showSuggestions) return const SizedBox.shrink();
                          return LocationAutocompleteDropdown(
                            isLoading: _locationAutocomplete.isLoading,
                            error: _locationAutocomplete.error,
                            suggestions: _locationAutocomplete.suggestions,
                            hasQuery: _locationAutocomplete.hasQuery,
                            onSelect: (suggestion) {
                              controller.zonaController.text = suggestion['display'] ?? '';
                              _locationAutocomplete.selectSuggestion();
                            },
                          );
                        },
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
                        style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Ej: 5000",
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                          prefix: Text("\$ ", style: TextStyle(color: AppColors.textPrimary)),
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
                        style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Contá un poco sobre vos y tu experiencia...",
                          hintStyle: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: ElevatedButton(
              onPressed: (_isLoading || !_isInitialized) ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
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
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLighter, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
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



