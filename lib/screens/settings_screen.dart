// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:manejapp/screens/debug_routing_screen.dart';
import 'package:manejapp/screens/legal_document_screen.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_input.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/config/app_environment.dart';
import 'package:manejapp/utils/support_launcher.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../utils/google_auth_helper.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'login_screen.dart';
import 'email_verification_pending_screen.dart';

const storage = appSecureStorage;

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = false;
  bool _notifPrefsLoading = true;
  bool _notifSaving = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricLabel = 'Biometría';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await BiometricService.canAuthenticate;
    final enabled = await BiometricService.isEnabled;
    final label = await BiometricService.biometricLabel;
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricLabel = label;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final authenticated = await BiometricService.authenticate(
        reason: 'Verificá tu identidad para activar $_biometricLabel',
      );
      if (!authenticated) {
        if (mounted) {
          AppFeedback.showError(
              context, 'No se pudo verificar $_biometricLabel');
        }
        return;
      }
    }
    await BiometricService.setEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _loadSettings() async {
    try {
      final remote = await ApiService.fetchNotificationPreferences();
      if (!mounted) return;
      if (remote != null) {
        setState(() {
          _emailNotifications = remote['emailNotifications'] == true;
          _pushNotifications = remote['pushNotifications'] == true &&
              NotificationService.isAvailable;
          _notifPrefsLoading = false;
        });
        await storage.write(
          key: 'email_notifications',
          value: _emailNotifications.toString(),
        );
        return;
      }
    } catch (_) {}
    final email = await storage.read(key: 'email_notifications');
    if (!mounted) return;
    setState(() {
      _emailNotifications = email != 'false';
      _notifPrefsLoading = false;
    });
  }

  Future<void> _persistNotificationPreferences() async {
    if (_notifSaving) return;
    setState(() => _notifSaving = true);
    try {
      await ApiService.putNotificationPreferences(
        emailNotifications: _emailNotifications,
        pushNotifications: _pushNotifications,
      );
      await storage.write(
        key: 'email_notifications',
        value: _emailNotifications.toString(),
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, humanizeApiError(e));
      }
      await _loadSettings();
    } finally {
      if (mounted) setState(() => _notifSaving = false);
    }
  }

  Future<void> _setEmailNotifications(bool enabled) async {
    setState(() => _emailNotifications = enabled);
    await _persistNotificationPreferences();
  }

  Future<void> _setPushNotifications(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.requestPermissionAndRegister();
      if (!granted) {
        if (mounted) {
          AppFeedback.showInfo(
            context,
            'Habilitá las notificaciones de ManejApp desde los ajustes del teléfono.',
          );
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() => _pushNotifications = enabled);
    await _persistNotificationPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: kReleaseMode
              ? null
              : () =>
                  Navigator.pushNamed(context, DebugRoutingScreen.routeName),
          child: Text('Configuración', style: AppTextStyles.heading),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveLayout.scrollPadding(context,
            base: const EdgeInsets.all(20)),
        child: Column(
          children: [
            _buildSectionTitle('Cuenta'),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingTile(Icons.lock_outline, 'Cambiar contraseña',
                      onTap: _showChangePasswordDialog),
                  const Divider(height: 1, color: AppColors.surfaceLighter),
                  _buildSettingTile(
                      Icons.email_outlined, 'Cambiar correo electrónico',
                      onTap: _showChangeEmailDialog),
                ],
              ),
            ),

            if (_biometricAvailable) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Seguridad'),
              AppCard(
                padding: const EdgeInsets.all(0),
                child: _buildSwitchTile(
                  _biometricLabel,
                  'Desbloqueo rápido al abrir la app',
                  _biometricEnabled,
                  _toggleBiometric,
                  icon: _biometricLabel == 'Face ID'
                      ? Icons.face
                      : Icons.fingerprint,
                ),
              ),
            ],

            const SizedBox(height: 24),

            _buildSectionTitle('Notificaciones'),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: _notifPrefsLoading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: [
                        _buildSwitchTile(
                          'Notificaciones push',
                          NotificationService.isAvailable
                              ? 'Reservas, pagos, recordatorios y aprobación de documentos'
                              : 'No disponibles en esta versión instalada',
                          _pushNotifications,
                          _notifSaving || !NotificationService.isAvailable
                              ? null
                              : _setPushNotifications,
                          icon: Icons.notifications_active_outlined,
                        ),
                        const Divider(
                            height: 1, color: AppColors.surfaceLighter),
                        _buildSwitchTile(
                          'Correo electrónico',
                          'Resúmenes y avisos por correo',
                          _emailNotifications,
                          _notifSaving
                              ? null
                              : (val) => _setEmailNotifications(val),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle('Soporte'),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingTile(Icons.help_outline, 'Centro de ayuda',
                      onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LegalDocumentScreen.help(),
                        ));
                  }),
                  const Divider(height: 1, color: AppColors.surfaceLighter),
                  _buildSettingTile(
                      Icons.description_outlined, 'Términos y condiciones',
                      onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LegalDocumentScreen.terms(),
                        ));
                  }),
                  const Divider(height: 1, color: AppColors.surfaceLighter),
                  _buildSettingTile(
                      Icons.privacy_tip_outlined, 'Política de privacidad',
                      onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LegalDocumentScreen.privacy(),
                        ));
                  }),
                  const Divider(height: 1, color: AppColors.surfaceLighter),
                  _buildSettingTile(
                    Icons.mail_outline_rounded,
                    'Escribir a soporte',
                    onTap: () => openSupportEmail(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            TextButton(
              onPressed: _onDeleteAccountPressed,
              child: Text('Eliminar cuenta',
                  style: AppTextStyles.bodyNormal
                      .copyWith(color: AppColors.error)),
            ),
            const SizedBox(height: 16),
            Text(AppEnvironment.versionLabel,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 40), // Bottom padding
          ],
        ),
      ),
    );
  }

  Future<void> _onDeleteAccountPressed() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        title: Text(
          'Eliminar cuenta',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
        content: Text(
          'Se anonimizarán tus datos personales y no podrás volver a iniciar sesión con esta cuenta. '
          'El historial de clases y pagos puede conservarse de forma agregada.',
          style: AppTextStyles.bodyNormal,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: AppTextStyles.bodyNormal
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Continuar',
              style: AppTextStyles.bodyNormal.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;

    bool hasGoogle = false;
    bool hasApple = false;
    try {
      final me = await ApiService.getMe();
      final u = me['user'];
      if (u is Map<String, dynamic>) {
        hasGoogle = u['hasGoogleLogin'] == true;
        hasApple = u['hasAppleLogin'] == true;
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
          context, 'No se pudo cargar tu perfil. Intentá de nuevo.');
      return;
    }

    final phraseCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final hasOAuth = hasGoogle || hasApple;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: Text(
            'Confirmación',
            style: AppTextStyles.heading.copyWith(fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escribí ELIMINAR en mayúsculas para confirmar.',
                  style: AppTextStyles.bodyNormal,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phraseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Escribí ELIMINAR',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                if (!hasOAuth) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancelar',
                style: AppTextStyles.bodyNormal
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                if (phraseCtrl.text.trim() != 'ELIMINAR') {
                  AppFeedback.showError(
                      ctx, 'Debés escribir exactamente ELIMINAR');
                  return;
                }
                if (!hasOAuth && passCtrl.text.isEmpty) {
                  AppFeedback.showError(ctx, 'Ingresá tu contraseña');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(
                'Eliminar definitivamente',
                style:
                    AppTextStyles.bodyNormal.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await ApiService.deleteAccount(
          confirmPhrase: 'ELIMINAR',
          password: hasGoogle ? null : passCtrl.text,
        );
      } finally {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      }

      await GoogleAuthHelper.signOut();
      await NotificationService.onLogout();
      await ApiService.logout();

      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Tu cuenta fue eliminada');
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      phraseCtrl.dispose();
      passCtrl.dispose();
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title,
                  style: AppTextStyles.bodyNormal.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool>? onChanged, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyNormal.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: AppTextStyles.bodyNormal.copyWith(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: Text('Cambiar contraseña',
              style: AppTextStyles.heading.copyWith(fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogInput(
                    'Contraseña actual', currentPasswordController,
                    isPassword: true),
                const SizedBox(height: 16),
                _buildDialogInput('Nueva contraseña', newPasswordController,
                    isPassword: true),
                const SizedBox(height: 16),
                _buildDialogInput(
                    'Confirmar contraseña', confirmPasswordController,
                    isPassword: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (currentPasswordController.text.isEmpty) {
                        AppFeedback.showError(
                            context, 'Ingresá tu contraseña actual');
                        return;
                      }
                      if (newPasswordController.text.isEmpty) {
                        AppFeedback.showError(
                            context, 'Ingresá la nueva contraseña');
                        return;
                      }
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        AppFeedback.showError(
                            context, 'Las contraseñas no coinciden');
                        return;
                      }
                      if (newPasswordController.text.length < 8 ||
                          !RegExp(r'[A-Za-záéíóúÁÉÍÓÚñÑ]')
                              .hasMatch(newPasswordController.text) ||
                          !RegExp(r'\d').hasMatch(newPasswordController.text)) {
                        AppFeedback.showError(
                          context,
                          'Usá al menos 8 caracteres, letras y números',
                        );
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        await ApiService.changePassword(
                          currentPasswordController.text,
                          newPasswordController.text,
                        );
                        if (context.mounted) {
                          await NotificationService.onLogout();
                          await ApiService.logout();
                          AppFeedback.showSuccess(context,
                              'Contraseña actualizada. Iniciá sesión nuevamente.');
                          Navigator.of(context, rootNavigator: true)
                              .pushNamedAndRemoveUntil(
                            LoginScreen.routeName,
                            (_) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppFeedback.showError(context, humanizeApiError(e));
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogInput(String label, TextEditingController controller,
      {bool isPassword = false}) {
    return AppInput(
      controller: controller,
      label: label,
      obscureText: isPassword,
      prefixIcon: isPassword
          ? Icons.lock_outline_rounded
          : Icons.alternate_email_rounded,
    );
  }

  void _showChangeEmailDialog() {
    final newEmailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surfaceLight,
          title: Text('Cambiar correo electrónico',
              style: AppTextStyles.heading.copyWith(fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogInput(
                    'Nuevo correo electrónico', newEmailController),
                const SizedBox(height: 16),
                _buildDialogInput('Contraseña actual', passwordController,
                    isPassword: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newEmailController.text.isEmpty) {
                        AppFeedback.showError(
                            context, 'Ingresá el nuevo correo electrónico');
                        return;
                      }
                      if (!newEmailController.text.contains('@')) {
                        AppFeedback.showError(
                            context, 'Ingresá un correo electrónico válido');
                        return;
                      }
                      if (passwordController.text.isEmpty) {
                        AppFeedback.showError(
                            context, 'Ingresá tu contraseña actual');
                        return;
                      }

                      setState(() => isLoading = true);
                      try {
                        await ApiService.changeEmail(
                          newEmailController.text,
                          passwordController.text,
                        );
                        if (context.mounted) {
                          await storage.write(
                              key: 'temp_email',
                              value: newEmailController.text.trim());
                          await storage.write(
                              key: 'temp_password',
                              value: passwordController.text);
                          await NotificationService.onLogout();
                          await ApiService.logout();
                          AppFeedback.showSuccess(context,
                              'Revisá el nuevo correo para verificarlo.');
                          Navigator.of(context, rootNavigator: true)
                              .pushNamedAndRemoveUntil(
                            EmailVerificationPendingScreen.routeName,
                            (_) => false,
                            arguments: newEmailController.text.trim(),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          AppFeedback.showError(context, humanizeApiError(e));
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }
}
