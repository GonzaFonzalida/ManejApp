import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/config/design_system.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import '../services/secure_storage.dart';
import '../utils/role_router.dart' show RoleRouter, kChooseRoleCompletedKey;
import '../utils/user_facing_error.dart';

const storage = appSecureStorage;

class ChooseRoleScreen extends StatefulWidget {
  static const routeName = '/choose_role';
  final String userId;
  const ChooseRoleScreen({super.key, required this.userId});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String _selectedRole = 'Alumno';
  final _experienceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _submitRole() async {
    if (_isLoading) {
      debugPrint('ChooseRoleScreen: _submitRole ignorado (ya loading)');
      return;
    }

    final roleLabel = _selectedRole;
    final role = roleLabel == 'Instructor' ? 'INSTRUCTOR' : 'STUDENT';
    final experienceText = _experienceController.text.trim();
    int? experienceYears;

    if (role == 'INSTRUCTOR') {
      experienceYears = int.tryParse(experienceText);
      if (experienceYears == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresá años de experiencia válidos')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    debugPrint('ChooseRoleScreen: _submitRole iniciado, isLoading=true');
    try {
      debugPrint('Intentando completar registro con userId: ${widget.userId}, role: $role');
      debugPrint('Experience: $experienceText');
      await ApiService.completeRegistration(
        widget.userId,
        role,
        experienceYears: role == 'INSTRUCTOR' ? experienceYears : null,
      );

      if (role == 'INSTRUCTOR') {
        final email = await storage.read(key: 'temp_email');
        final password = await storage.read(key: 'temp_password');
        if (email != null && password != null) {
          debugPrint('[RoleRouter] choose_role: refreshing token after role change');
          await ApiService.login(email, password);
          unawaited(NotificationService.registerTokenWithBackendIfLoggedIn());
        }
      }

      final hasAuthToken = await storage.read(key: 'auth_token') != null;

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      if (hasAuthToken) {
        await storage.write(key: kChooseRoleCompletedKey, value: widget.userId);
        await storage.delete(key: 'temp_email');
        await storage.delete(key: 'temp_password');
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              role == 'STUDENT'
                  ? '¡Genial! Siguiente: unos pasos para dejar tu perfil listo.'
                  : '¡Registro completado! Bienvenido a ManejApp',
            ),
          ),
        );
        final target = await RoleRouter.resolveRouteForCurrentUser(context: 'choose_role(hasToken)');
        debugPrint('[RoleRouter] choose_role(hasToken) → $target');
        if (!mounted) return;
        unawaited(NotificationService.registerTokenWithBackendIfLoggedIn());
        navigator.pushReplacementNamed(target);
      } else {
        final email = await storage.read(key: 'temp_email');
        final password = await storage.read(key: 'temp_password');
        if (email != null && password != null) {
          try {
            await ApiService.login(email, password);
            await storage.write(key: kChooseRoleCompletedKey, value: widget.userId);
            await storage.delete(key: 'temp_email');
            await storage.delete(key: 'temp_password');
            if (mounted) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    role == 'STUDENT'
                        ? '¡Genial! Siguiente: unos pasos para dejar tu perfil listo.'
                        : '¡Registro completado! Bienvenido a ManejApp',
                  ),
                ),
              );
              final target = await RoleRouter.resolveRouteForCurrentUser(context: 'choose_role(afterLogin)');
              debugPrint('[RoleRouter] choose_role(afterLogin) → $target');
              if (!mounted) return;
              unawaited(NotificationService.registerTokenWithBackendIfLoggedIn());
              navigator.pushReplacementNamed(target);
            }
          } catch (_) {
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Registro completado. Iniciá sesión para continuar')),
              );
              navigator.pushReplacementNamed(LoginScreen.routeName);
            }
          }
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('Registro completado. Iniciá sesión para continuar')),
          );
          navigator.pushReplacementNamed(LoginScreen.routeName);
        }
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('ChooseRoleScreen: Error en _submitRole: $e');
      final msg = humanizeApiError(e);
      final is409AlreadyExists = msg.contains('409') || msg.contains('ya existe') || msg.contains('already');
      if (is409AlreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este rol ya estaba registrado. Continuá a inicio.'),
            backgroundColor: AppColors.success,
          ),
        );
        final navigator = Navigator.of(context);
        final target = await RoleRouter.resolveRouteForCurrentUser(context: 'choose_role(409)');
        debugPrint('[RoleRouter] choose_role(409) → $target');
        if (!mounted) return;
        await storage.write(key: kChooseRoleCompletedKey, value: widget.userId);
        unawaited(NotificationService.registerTokenWithBackendIfLoggedIn());
        navigator.pushReplacementNamed(target);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('ChooseRoleScreen: _submitRole finalizado, isLoading=false');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.panel,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'COMPLETÁ TU PERFIL',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyNormal.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.compact),
              Text(
                'Elegí tu rol',
                textAlign: TextAlign.center,
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Elegí cómo vas a usar ManejApp. Si sos alumno, en el siguiente paso personalizamos tu perfil en minutos.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyNormal.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                '¿Cómo vas a usar la app?',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.compact),
              _buildRoleCard(
                role: 'Alumno',
                description: 'Aprendé con instructores verificados.',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.compact),
              _buildRoleCard(
                role: 'Instructor',
                description: 'Enseñá y gestioná tus clases.',
                icon: Icons.school_outlined,
              ),
              if (_selectedRole == 'Instructor') ...[
                const SizedBox(height: AppSpacing.lg),
                _buildPremiumPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Información adicional',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Indicá tu experiencia como instructor. La licencia de conducir la validamos con la foto del documento en el siguiente paso.',
                        style: AppTextStyles.bodyNormal.copyWith(
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.panel),
                      _buildTextField(
                        controller: _experienceController,
                        label: 'Años de experiencia',
                        icon: Icons.timeline_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              AppButton(
                text: 'Completar registro',
                onPressed: _isLoading ? null : _submitRole,
                isLoading: _isLoading,
                type: AppButtonType.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumPanel({required Widget child}) {
    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: AppCurves.emphasized,
      padding: const EdgeInsets.all(AppSpacing.panel),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.panel),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: AppStroke.hairline,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: child,
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedRole = role);
        },
        borderRadius: BorderRadius.circular(AppRadius.panel),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: AnimatedScale(
          scale: isSelected ? 1.01 : 1.0,
          duration: AppDurations.normal,
          curve: AppCurves.emphasized,
          child: AnimatedContainer(
            duration: AppDurations.normal,
            curve: AppCurves.emphasized,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.panel,
              vertical: AppSpacing.panel,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.panel),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? AppStroke.emphasis : AppStroke.hairline,
              ),
              boxShadow: isSelected ? AppShadows.roleCardSelected(AppColors.primary) : AppShadows.sm,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppDurations.normal,
                  curve: AppCurves.emphasized,
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description,
                        style: AppTextStyles.bodyNormal.copyWith(
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: AnimatedSwitcher(
                    duration: AppDurations.normal,
                    switchInCurve: AppCurves.emphasized,
                    switchOutCurve: Curves.easeInCubic,
                    child: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey<String>('check-$role'),
                            color: AppColors.primary,
                            size: 26,
                          )
                        : const SizedBox(
                            key: ValueKey<String>('no-check'),
                            width: 28,
                            height: 28,
                          ),
                  ),
                ),
              ],
            ),
          ),
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
    final r = BorderRadius.circular(AppRadius.md);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
        border: OutlineInputBorder(borderRadius: r),
        enabledBorder: OutlineInputBorder(
          borderRadius: r,
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: AppStroke.hairline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: r,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: AppColors.surfaceLighter,
        labelStyle: AppTextStyles.bodyNormal.copyWith(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
