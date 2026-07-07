import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/utils/student_profile_completion.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/widgets/skeleton_loader.dart';
import 'editar_perfil_screen.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import '../services/notification_service.dart';
import '../utils/google_auth_helper.dart';
import 'package:intl/intl.dart';

const storage = appSecureStorage;

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
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loadError = null;
        _loading = true;
      });
    } else if (silent && mounted) {
      setState(() => _loadError = null);
    }
    try {
    final userId = await storage.read(key: 'user_id');
    if (userId != null) {
      final profile = await ApiService.getUserProfile(userId);
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _profileImageUrl = profile['profileImageUrl'] as String?;
          _imageTimestamp = DateTime.now().millisecondsSinceEpoch;
          _hourlyRate = profile['hourlyRate'] as double?;
          _loadError = null;
          _loading = false;
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
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'No encontramos tu sesión. Volvé a iniciar sesión.';
        });
      }
    }
    } catch (e) {
      debugPrint('Error cargando perfil: $e');
      if (e.toString().toLowerCase().contains('expira') || e.toString().contains('401')) {
          if (mounted) {
              Future.delayed(Duration.zero, () {
                 if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              });
          }
          return;
      }
      if (mounted) {
        if (silent) {
          AppFeedback.showError(context, humanizeApiError(e));
        } else {
          setState(() {
            _loading = false;
            _loadError = humanizeApiError(e);
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text('Cerrar Sesión', style: AppTextStyles.heading.copyWith(fontSize: 20)),
        content: Text('¿Estás seguro de que quieres cerrar sesión?', style: AppTextStyles.bodyNormal),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textSecondary)),
          ),
          AppButton(
             text: 'Cerrar Sesión',
             onPressed: () => Navigator.pop(context, true),
             type: AppButtonType.primary,
          ).width(130).height(40),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await GoogleAuthHelper.signOut();
        await NotificationService.onLogout();
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
          AppFeedback.showError(context, humanizeApiError(e));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mi Perfil', style: AppTextStyles.heading),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _loading && _profile == null
          ? const Center(child: CardSkeletonLoader())
          : _loadError != null && _profile == null
              ? Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: AppErrorState(
                      title: 'No pudimos cargar tu perfil',
                      message: _loadError,
                      onRetry: _loadProfile,
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceLight,
                  onRefresh: () => _loadProfile(silent: true),
                  child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Profile
            Semantics(
              label: 'Editar perfil',
              button: true,
              child: GestureDetector(
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
                    backgroundColor: AppColors.surfaceLighter,
                    backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage('$_profileImageUrl?t=$_imageTimestamp')
                        : null,
                    child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                        ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceLight,
                        border: Border.all(color: AppColors.background, width: 3),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.edit,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_profile?['firstName'] ?? _profile?['name'] ?? ''} ${_profile?['lastName'] ?? _profile?['surname'] ?? ''}',
              style: AppTextStyles.heading,
            ),
            if (_profile?['role'] == 'STUDENT')
               Container(
                 margin: const EdgeInsets.only(top: 8),
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                 decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                 child: Text('ESTUDIANTE', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
               ),
            if (_profile != null && _profile!['role'] == 'STUDENT') ...[
              const SizedBox(height: 20),
              _buildStudentCompletionSection(),
            ],
            
            const SizedBox(height: 32),

            // Personal Info Section
            _buildSectionTitle('Información Personal'),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                    _buildProfileTile(Icons.person_outline, "Nombre completo", '${_profile?['firstName'] ?? _profile?['name'] ?? ''} ${_profile?['lastName'] ?? _profile?['surname'] ?? ''}'),
                    const Divider(height: 1, color: AppColors.surfaceLighter),
                    _buildProfileTile(Icons.email_outlined, "Email", _profile?['email'] ?? "usuario@email.com"),
                    const Divider(height: 1, color: AppColors.surfaceLighter),
                    _buildProfileTile(Icons.calendar_today_outlined, "Fecha de nacimiento", _formatDate(_profile?['birthDate'])),
                    const Divider(height: 1, color: AppColors.surfaceLighter),
                    _buildProfileTile(Icons.phone_outlined, "Teléfono", _profile?['phoneNumber'] ?? "No especificado"),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Addresses Section
            _buildSectionTitle('Ubicación'),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildProfileTile(Icons.location_on_outlined, "Dirección Principal", _profile?['location'] ?? "No especificada", showEdit: true, onTap: _editLocation),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Cerrar Sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
                ),
    );
  }

  Widget _buildStudentCompletionSection() {
    final p = _profile!;
    final pct = StudentProfileCompletion.completionPercent(p);
    final next = StudentProfileCompletion.promptsFor(p);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Perfil completo',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: AppTextStyles.heading.copyWith(fontSize: 20, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLighter,
              color: AppColors.primary,
            ),
          ),
          if (next.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Te recomendamos',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            ...next.take(3).map(
                  (hint) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18, color: AppColors.primary.withOpacity(0.8)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hint.title, style: AppTextStyles.bodyNormal.copyWith(fontWeight: FontWeight.w600)),
                              Text(
                                hint.subtitle,
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            TextButton(
              onPressed: () async {
                final ok = await Navigator.pushNamed(context, EditarPerfilScreen.routeName);
                if (ok == true && mounted) await _loadProfile();
              },
              child: Text('Completar en editar perfil', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      ),
    );
  }

  Future<void> _editLocation() async {
    final controller = TextEditingController(
      text: (_profile?['location'] ?? '').toString(),
    );
    final newValue = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Editar dirección', style: AppTextStyles.heading.copyWith(fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          maxLength: 120,
          decoration: const InputDecoration(
            hintText: 'Ej. Av. Corrientes 1234, CABA',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (newValue == null) return;

    final userId = await storage.read(key: 'user_id');
    if (userId == null) {
      if (mounted) AppFeedback.showError(context, 'No se encontró tu usuario.');
      return;
    }

    try {
      await ApiService.updateUser(userId, {'location': newValue});
      if (mounted) {
        AppFeedback.showSuccess(context, 'Dirección actualizada');
        await _loadProfile(silent: true);
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, humanizeApiError(e));
    }
  }

  Widget _buildProfileTile(IconData icon, String title, String value, {bool showEdit = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surfaceLighter, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyNormal.copyWith(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: AppTextStyles.bodyNormal.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
              ),
            ),
            if (showEdit)
               Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
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

extension WidgetExt on Widget {
    Widget width(double w) => SizedBox(width: w, child: this);
    Widget height(double h) => SizedBox(height: h, child: this);
}
