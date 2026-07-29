import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';

class VerifyEmailScreen extends StatefulWidget {
  static const routeName = '/verify-email';
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;
  String? _token;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_token != null || _isLoading || _error != null) return;

    final token = ModalRoute.of(context)?.settings.arguments as String?;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'El enlace de verificación no es válido.');
      return;
    }
    _token = token;
    _verifyEmail();
  }

  Future<void> _verifyEmail() async {
    final token = _token;
    if (token == null || token.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ApiService.verifyEmail(token);

      const storage = appSecureStorage;
      final userId = await storage.read(key: 'user_id');
      final email = await storage.read(key: 'temp_email');
      final password = await storage.read(key: 'temp_password');

      var sessionReady = false;
      if (email != null && password != null) {
        try {
          await ApiService.login(email, password);
          sessionReady = true;
        } catch (_) {
          sessionReady = false;
        }
      }

      if (!mounted) return;
      if (userId != null && sessionReady) {
        Navigator.of(context)
            .pushReplacementNamed('/choose_role', arguments: userId);
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = humanizeApiError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Verificación de cuenta'),
      ),
      body: ResponsiveScrollBody(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        centerWhenShort: true,
        child: _error == null ? _buildCheckingState() : _buildErrorState(),
      ),
    );
  }

  Widget _buildCheckingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            children: [
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Estamos verificando tu correo',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Esperá unos segundos. Cuando terminemos, te vamos a llevar al próximo paso automáticamente.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: AppErrorState(
            title: 'No pudimos verificar tu correo',
            message: _error,
            retryLabel: 'Intentar de nuevo',
            onRetry: _token == null ? null : _verifyEmail,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          text: 'Ir a iniciar sesión',
          type: AppButtonType.outline,
          onPressed: _goToLogin,
        ),
      ],
    );
  }
}
