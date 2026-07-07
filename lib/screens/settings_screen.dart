// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:manejapp/screens/debug_routing_screen.dart';
import 'package:manejapp/screens/legal_document_screen.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../utils/google_auth_helper.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'login_screen.dart';
import '../providers/theme_provider.dart';

const storage = appSecureStorage;

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo verificar $_biometricLabel'),
              backgroundColor: AppColors.error,
            ),
          );
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
        pushNotifications: false,
      );
      await storage.write(
        key: 'email_notifications',
        value: _emailNotifications.toString(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(humanizeApiError(e)),
            backgroundColor: AppColors.error,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
         title: GestureDetector(
           onLongPress: kReleaseMode
               ? null
               : () => Navigator.pushNamed(context, DebugRoutingScreen.routeName),
           child: Text('Configuración', style: AppTextStyles.heading),
         ),
         backgroundColor: AppColors.background,
         elevation: 0,
         automaticallyImplyLeading: Navigator.of(context).canPop(),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveLayout.scrollPadding(context, base: const EdgeInsets.all(20)),
        child: Column(
          children: [
            _buildSectionTitle('Cuenta'),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingTile(Icons.lock_outline, 'Cambiar Contraseña', onTap: _showChangePasswordDialog),
                  const Divider(height: 1, color: AppColors.surfaceLighter),
                  _buildSettingTile(Icons.email_outlined, 'Cambiar Email', onTap: _showChangeEmailDialog),
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
                  icon: _biometricLabel == 'Face ID' ? Icons.face : Icons.fingerprint,
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
                        ListTile(
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                            color: AppColors.textSecondary,
                          ),
                          title: Text(
                            'Notificaciones push',
                            style: AppTextStyles.bodyNormal.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Próximamente. Por ahora revisá tus reservas en la app y activá avisos por email si querés.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLighter,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Próximamente',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.surfaceLighter),
                        _buildSwitchTile(
                          'Email',
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
            
            _buildSectionTitle('Apariencia'),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: Consumer<ThemeProvider>(
                 builder: (context, themeProvider, _) => _buildSwitchTile(
                    'Modo Oscuro', 
                    'Cambiar tema de la app', 
                    themeProvider.isDarkMode, 
                    (_) => themeProvider.toggleTheme(),
                    icon: themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                 ),
              ),
            ),

            const SizedBox(height: 24),
            
            _buildSectionTitle('Soporte'),
            AppCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildSettingTile(Icons.help_outline, 'Centro de Ayuda', onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LegalDocumentScreen.help(),
                    ));
                  }),
                  const Divider(height: 1, color: AppColors.surfaceLighter),
                  _buildSettingTile(Icons.description_outlined, 'Términos y Condiciones', onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LegalDocumentScreen.terms(),
                    ));
                  }),
                  const Divider(height: 1, color: AppColors.surfaceLighter),
                  _buildSettingTile(Icons.privacy_tip_outlined, 'Política de Privacidad', onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LegalDocumentScreen.privacy(),
                    ));
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            TextButton(
               onPressed: _onDeleteAccountPressed,
               child: Text('Eliminar Cuenta', style: AppTextStyles.bodyNormal.copyWith(color: AppColors.error)),
            ),
            const SizedBox(height: 16),
            Text('Versión 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
              style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textSecondary),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar tu perfil. Intentá de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
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
                style: AppTextStyles.bodyNormal.copyWith(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                if (phraseCtrl.text.trim() != 'ELIMINAR') {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Debés escribir exactamente ELIMINAR')),
                  );
                  return;
                }
                if (!hasOAuth && passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Contraseña requerida')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(
                'Eliminar definitivamente',
                style: AppTextStyles.bodyNormal.copyWith(color: AppColors.error),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu cuenta fue eliminada')),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(humanizeApiError(e)),
          backgroundColor: AppColors.error,
        ),
      );
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
        child: Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyNormal.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                 Text(title, style: AppTextStyles.bodyNormal.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                 Text(subtitle, style: AppTextStyles.bodyNormal.copyWith(fontSize: 12, color: AppColors.textSecondary)),
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
          title: Text('Cambiar Contraseña', style: AppTextStyles.heading.copyWith(fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogInput('Contraseña Actual', currentPasswordController, isPassword: true),
              const SizedBox(height: 16),
              _buildDialogInput('Nueva Contraseña', newPasswordController, isPassword: true),
              const SizedBox(height: 16),
              _buildDialogInput('Confirmar Contraseña', confirmPasswordController, isPassword: true),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa tu contraseña actual')),
                  );
                  return;
                }
                if (newPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa la nueva contraseña')),
                  );
                  return;
                }
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Las contraseñas no coinciden')),
                  );
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
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
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contraseña actualizada exitosamente'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(humanizeApiError(e)), backgroundColor: AppColors.error),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    setState(() => isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDialogInput(String label, TextEditingController controller, {bool isPassword = false}) {
      return TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.surfaceLighter)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
        ),
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
          title: Text('Cambiar Email', style: AppTextStyles.heading.copyWith(fontSize: 20)),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogInput('Nuevo Email', newEmailController),
              const SizedBox(height: 16),
              _buildDialogInput('Contraseña Actual', passwordController, isPassword: true),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (newEmailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa el nuevo email')),
                  );
                  return;
                }
                if (!newEmailController.text.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un email válido')),
                  );
                  return;
                }
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa tu contraseña actual')),
                  );
                  return;
                }

                setState(() => isLoading = true);
                try {
                  await ApiService.changeEmail(
                    newEmailController.text,
                    passwordController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email actualizado exitosamente'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(humanizeApiError(e)), backgroundColor: AppColors.error),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    setState(() => isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }
}
