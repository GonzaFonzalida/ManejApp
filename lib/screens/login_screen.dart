import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../controllers/login_controller.dart'
    show LoginController, navigateAfterAuth;
import '../services/config_service.dart';
import '../widgets/google_sign_in_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../config/design_system.dart';
import '../widgets/design/app_button.dart';
import '../widgets/design/app_card.dart';
import '../widgets/design/app_input.dart';
import '../utils/app_feedback.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final controller = LoginController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    controller.loadSavedCredentials(() => setState(() {}));
    ConfigService.loadConfig();
  }

  Future<void> _handleGoogleLoginSuccess(BuildContext context) async {
    if (!context.mounted) return;
    final routed = await navigateAfterAuth(context, 'login_screen(google)');
    if (!context.mounted || !routed) return;
    AppFeedback.showSuccess(context, 'Sesión iniciada correctamente');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xl + bottomInset + keyboardInset,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      AppSpacing.xxl,
                ),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHero(),
                      SizedBox(height: AppSpacing.xxl),
                      Text(
                        'Qué bueno verte de nuevo',
                        style: AppTextStyles.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Ingresá con tu cuenta para continuar',
                        style: AppTextStyles.bodyNormal
                            .copyWith(fontSize: 15, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.xl),
                      AppCard(
                        variant: AppCardVariant.outlined,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppInput(
                              label: 'Correo electrónico',
                              hint: 'nombre@correo.com',
                              controller: controller.emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.alternate_email_rounded,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresá tu correo electrónico';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value.trim())) {
                                  return 'Correo electrónico inválido';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: AppSpacing.lg),
                            AppInput(
                              label: 'Contraseña',
                              hint: '••••••••',
                              controller: controller.passwordController,
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) =>
                                  value == null || value.length < 6
                                      ? 'Mínimo 6 caracteres'
                                      : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, ForgotPasswordScreen.routeName),
                                child: Text(
                                  '¿Olvidaste tu contraseña?',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  child: Checkbox(
                                    value: controller.rememberMe,
                                    onChanged: (v) {
                                      setState(() =>
                                          controller.rememberMe = v ?? false);
                                    },
                                    activeColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.divider, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      controller.rememberMe =
                                          !controller.rememberMe;
                                    }),
                                    child: Text(
                                      'Recordar mi correo en este dispositivo',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSpacing.md),
                            AppButton(
                              text: 'Iniciar sesión',
                              onPressed: controller.isLoading
                                  ? null
                                  : () => controller.submit(
                                      context, () => setState(() {})),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      _buildDividerLabel('o continuá con'),
                      SizedBox(height: AppSpacing.lg),
                      _buildGoogleButton(context),
                      if (!kIsWeb &&
                          defaultTargetPlatform == TargetPlatform.iOS) ...[
                        SizedBox(height: AppSpacing.md),
                        _buildAppleButton(context),
                      ],
                      SizedBox(height: AppSpacing.xxl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('¿No tenés cuenta?',
                              style: AppTextStyles.bodyNormal),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, RegisterScreen.routeName),
                            child: Text(
                              'Crear cuenta',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (controller.isLoading)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: AppColors.overlay.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: AppShadows.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'Iniciando sesión…',
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppDurations.slow,
      curve: AppCurves.emphasized,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              boxShadow: AppShadows.sm,
            ),
            child: Icon(
              Icons.directions_car_filled_rounded,
              size: 52,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.displayLarge
                  .copyWith(fontSize: 30, letterSpacing: -0.5),
              children: const [
                TextSpan(text: 'Manej'),
                TextSpan(
                    text: 'App', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerLabel(String label) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: AppColors.divider.withValues(alpha: 0.6), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
            child: Divider(
                color: AppColors.divider.withValues(alpha: 0.6), thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    if (kIsWeb) {
      return buildGoogleSignInButton(
        context,
        onSuccess: () => _handleGoogleLoginSuccess(context),
        onError: () {
          if (mounted) {
            AppFeedback.showError(
                context, 'No se pudo iniciar sesión con Google');
          }
        },
        onLoadingChanged: () => setState(() {}),
      );
    }

    return AppButton(
      text: 'Continuar con Google',
      type: AppButtonType.outline,
      icon: Icons.g_mobiledata_rounded,
      onPressed: controller.isLoading
          ? null
          : () => controller.loginWithGoogle(context, () => setState(() {})),
    );
  }

  Widget _buildAppleButton(BuildContext context) {
    return AppButton(
      text: 'Continuar con Apple',
      type: AppButtonType.outline,
      icon: Icons.apple,
      onPressed: controller.isLoading
          ? null
          : () => controller.loginWithApple(context, () => setState(() {})),
    );
  }
}
