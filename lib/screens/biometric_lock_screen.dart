import 'package:flutter/material.dart';

import '../config/design_system.dart';
import '../widgets/responsive_scroll_body.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../services/session_manager.dart';
import 'login_screen.dart';

/// Gate screen shown when the user has a persisted session and biometric unlock
/// is enabled. It prompts Face ID / Touch ID automatically on mount and lets
/// the user retry or fall back to the regular login flow.
class BiometricLockScreen extends StatefulWidget {
  static const routeName = '/biometric_lock';
  final String targetRoute;

  const BiometricLockScreen({super.key, required this.targetRoute});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _authenticating = false;
  String? _error;
  String _biometricLabel = 'Biometría';

  @override
  void initState() {
    super.initState();
    _loadLabel();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptBiometric());
  }

  Future<void> _loadLabel() async {
    final label = await BiometricService.biometricLabel;
    if (mounted) setState(() => _biometricLabel = label);
  }

  Future<void> _promptBiometric() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final success = await BiometricService.authenticate(
      reason: 'Desbloqueá ManejApp con $_biometricLabel',
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, widget.targetRoute);
    } else {
      setState(() {
        _authenticating = false;
        _error = '$_biometricLabel no reconocido. Intentá de nuevo.';
      });
    }
  }

  Future<void> _fallbackToLogin() async {
    await NotificationService.onLogout();
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveScrollBody(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        centerWhenShort: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_filled,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: AppTextStyles.displayLarge.copyWith(fontSize: 28),
                children: const [
                  TextSpan(text: 'Manej'),
                  TextSpan(
                    text: 'App',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Icon(
              _biometricLabel == 'Face ID' ? Icons.face : Icons.fingerprint,
              size: 64,
              color: _error != null
                  ? AppColors.error.withValues(alpha: 0.7)
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 20),
            if (_authenticating)
              Text(
                'Verificando $_biometricLabel...',
                style: AppTextStyles.bodyNormal.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              )
            else if (_error != null)
              Text(
                _error!,
                style: AppTextStyles.bodyNormal.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                'Usá $_biometricLabel para desbloquear',
                style: AppTextStyles.bodyNormal.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            if (!_authenticating) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _promptBiometric,
                  icon: Icon(
                    _biometricLabel == 'Face ID'
                        ? Icons.face
                        : Icons.fingerprint,
                    size: 20,
                  ),
                  label: Text('Reintentar $_biometricLabel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _fallbackToLogin,
                child: Text(
                  'Usar contraseña',
                  style: AppTextStyles.bodyNormal.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
