import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';
import 'login_screen.dart';

class EmailVerificationPendingScreen extends StatefulWidget {
  static const routeName = '/email-verification-pending';
  const EmailVerificationPendingScreen({super.key});

  @override
  State<EmailVerificationPendingScreen> createState() =>
      _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState
    extends State<EmailVerificationPendingScreen> {
  String? _email;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<void> _resendVerification() async {
    final email = _email;
    if (email == null || email.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.resendVerification(email);
      if (!mounted) return;
      AppFeedback.showSuccess(
          context, 'Te reenviamos el correo de verificación');
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Verificá tu correo')),
      body: ResponsiveScrollBody(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        centerWhenShort: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Semantics(
                image: true,
                label: 'Correo pendiente de verificación',
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.14),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Te enviamos un enlace',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _email == null || _email!.isEmpty
                  ? 'Revisá tu correo y tocá el enlace para verificar tu cuenta.'
                  : 'Revisá $_email y tocá el enlace para verificar tu cuenta.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              variant: AppCardVariant.outlined,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 24),
                  const SizedBox(width: AppSpacing.compact),
                  Expanded(
                    child: Text(
                      'El enlace vuelve a ManejApp y completa la verificación de forma segura. Si no lo encontrás, revisá spam o correo no deseado.',
                      style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Reenviar correo',
              icon: Icons.refresh_rounded,
              onPressed: _email == null || _email!.isEmpty || _isLoading
                  ? null
                  : _resendVerification,
              isLoading: _isLoading,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Ya verifiqué mi cuenta',
              type: AppButtonType.outline,
              onPressed: _goToLogin,
            ),
          ],
        ),
      ),
    );
  }
}
