import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_input.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';

class ResetPasswordScreen extends StatefulWidget {
  static const routeName = '/reset-password';

  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  String? _token;
  bool _loading = false;
  bool _completed = false;
  bool _hidePassword = true;
  bool _hideConfirmation = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _token ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) return 'Usá al menos 8 caracteres';
    if (!RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(password)) {
      return 'Incluí al menos una letra';
    }
    if (!RegExp(r'\d').hasMatch(password)) return 'Incluí al menos un número';
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final token = _token;
    if (token == null || token.isEmpty) {
      AppFeedback.showError(context, 'El enlace no es válido. Pedí uno nuevo.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ApiService.resetPassword(token, _passwordController.text);
      if (!mounted) return;
      setState(() => _completed = true);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
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
        automaticallyImplyLeading: !_completed,
        title: const Text('Nueva contraseña'),
      ),
      body: ResponsiveScrollBody(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        centerWhenShort: true,
        child: AnimatedSwitcher(
          duration: AppDurations.normal,
          child: _completed ? _buildCompleted() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AutofillGroup(
      key: const ValueKey('reset-form'),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statusIcon(Icons.lock_reset_rounded, AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Protegé tu cuenta',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Elegí una contraseña nueva de al menos 8 caracteres, con letras y números.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              child: Column(
                children: [
                  AppInput(
                    label: 'Contraseña nueva',
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(_hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppInput(
                    label: 'Repetí la contraseña',
                    controller: _confirmationController,
                    obscureText: _hideConfirmation,
                    prefixIcon: Icons.lock_outline_rounded,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    validator: _validateConfirmation,
                    onFieldSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      tooltip: _hideConfirmation
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      onPressed: () => setState(
                          () => _hideConfirmation = !_hideConfirmation),
                      icon: Icon(_hideConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'Guardar contraseña',
                    icon: Icons.check_rounded,
                    onPressed: _loading ? null : _submit,
                    isLoading: _loading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleted() {
    return Column(
      key: const ValueKey('reset-completed'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusIcon(Icons.check_rounded, AppColors.success),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Contraseña actualizada',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'El cambio quedó guardado. Ya podés iniciar sesión con tu contraseña nueva.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(text: 'Iniciar sesión', onPressed: _goToLogin),
      ],
    );
  }

  Widget _statusIcon(IconData icon, Color color) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
        ),
        child: Icon(icon, size: 44, color: color),
      ),
    );
  }
}
