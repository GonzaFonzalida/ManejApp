import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_input.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/forgot-password';
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresá tu correo electrónico';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Ingresá un correo electrónico válido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Recuperá tu contraseña')),
      body: ResponsiveScrollBody(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        centerWhenShort: true,
        child: AutofillGroup(
          child: AnimatedSwitcher(
            duration: AppDurations.normal,
            child: _sent ? _buildSentState() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('forgot-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon(Icons.lock_reset_rounded, AppColors.primary),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Volvé a entrar a tu cuenta',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ingresá tu correo y te vamos a enviar un enlace seguro para crear una contraseña nueva.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                AppInput(
                  label: 'Correo electrónico',
                  hint: 'nombre@correo.com',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: 'Enviar enlace',
                  icon: Icons.send_rounded,
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          text: 'Volver a iniciar sesión',
          type: AppButtonType.ghost,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSentState() {
    return Column(
      key: const ValueKey('forgot-sent'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIcon(Icons.mark_email_read_rounded, AppColors.success),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Revisá tu correo',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Si existe una cuenta asociada, vas a recibir un enlace para restablecer tu contraseña. Revisá también la carpeta de spam.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          text: 'Volver a iniciar sesión',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          text: 'Enviar de nuevo',
          type: AppButtonType.ghost,
          onPressed: _isLoading ? null : _submit,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Center(
      child: Semantics(
        image: true,
        label: _sent ? 'Correo enviado' : 'Recuperar contraseña',
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
          ),
          child: Icon(icon, size: 44, color: color),
        ),
      ),
    );
  }
}
