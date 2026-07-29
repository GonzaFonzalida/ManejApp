import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_input.dart';
import 'package:manejapp/widgets/design/app_flow_progress.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/google_auth_helper.dart';
import 'package:manejapp/utils/apple_auth_helper.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/utils/whatsapp.dart';
import '../controllers/login_controller.dart' show navigateAfterAuth;
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'login_screen.dart';
import 'choose_role_screen.dart';
import 'package:manejapp/screens/email_verification_pending_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _accountFormKey = GlobalKey<FormState>();
  final _identityFormKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _whatsappController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  int _step = 0;

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year - 16, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(now.year - 110),
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.textInverse,
              surface: AppColors.surfaceLight,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (_accountFormKey.currentState?.validate() != true ||
        _identityFormKey.currentState?.validate() != true) {
      return;
    }

    if (_selectedDate == null) {
      AppFeedback.showError(context, 'Seleccioná tu fecha de nacimiento');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final reg = await ApiService.register(
        _nameController.text.trim(),
        _surnameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _dniController.text.trim(),
        DateFormat('yyyy-MM-dd').format(_selectedDate!),
        phoneNumber: normalizeWhatsAppNumber(_whatsappController.text),
      );
      final userId = reg.userId;

      if (!mounted) return;

      if (userId.isNotEmpty) {
        final hasAuthToken = await SessionManager.hasSession;
        if (!mounted) return;

        if (hasAuthToken) {
          AppFeedback.showSuccess(context,
              '¡Listo! Siguiente: elegí tu rol y completá tu perfil en unos pasos.');
          Navigator.pushReplacementNamed(context, ChooseRoleScreen.routeName,
              arguments: userId);
        } else {
          AppFeedback.showSuccess(
            context,
            reg.serverMessage ??
                'Registro exitoso. Revisá tu correo electrónico.',
          );
          Navigator.pushReplacementNamed(
            context,
            EmailVerificationPendingScreen.routeName,
            arguments: _emailController.text.trim(),
          );
        }
      } else {
        AppFeedback.showError(context, 'Error: UserId vacío');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = humanizeApiError(e);

      if (msg.contains('ya existe')) {
        AppFeedback.showInfo(context,
            'Ya existe una cuenta con esos datos. Te llevamos a iniciar sesión…');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, LoginScreen.routeName);
          }
        });
      } else {
        AppFeedback.showError(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading || _isGoogleLoading || _isAppleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final result = await GoogleAuthHelper.signIn();
      if (result == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      if (!mounted) return;
      await navigateAfterAuth(context, 'register(google)');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        humanizeApiError(e),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _loginWithApple() async {
    if (_isLoading || _isGoogleLoading || _isAppleLoading) return;
    setState(() => _isAppleLoading = true);
    try {
      final result = await AppleAuthHelper.signIn();
      if (result == null) {
        if (mounted) setState(() => _isAppleLoading = false);
        return;
      }

      if (!mounted) return;
      await navigateAfterAuth(context, 'register(apple)');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        humanizeApiError(e),
      );
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  bool get _busy => _isLoading || _isGoogleLoading || _isAppleLoading;

  void _continueToIdentity() {
    if (_accountFormKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() => _step = 1);
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step == 1) {
      HapticFeedback.selectionClick();
      setState(() => _step = 0);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: _goBack,
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg,
                  AppSpacing.xxl + bottom + keyboardInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  SizedBox(height: AppSpacing.xl),
                  AnimatedSwitcher(
                    duration: AppMotion.duration(context, AppDurations.normal),
                    child:
                        _step == 0 ? _buildAccountStep() : _buildIdentityStep(),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('¿Ya tenés cuenta?',
                          style: AppTextStyles.bodyNormal),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, LoginScreen.routeName),
                        child: Text(
                          'Iniciar sesión',
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
          if (_busy)
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
                          _isGoogleLoading
                              ? 'Conectando con Google…'
                              : _isAppleLoading
                                  ? 'Conectando con Apple…'
                                  : 'Creando tu cuenta…',
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
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

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        letterSpacing: 1.1,
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }

  Widget _buildAccountStep() {
    return Column(
      key: const ValueKey('register-account-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          variant: AppCardVariant.outlined,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _accountFormKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionLabel('Datos de acceso'),
                SizedBox(height: AppSpacing.md),
                AppInput(
                  controller: _nameController,
                  label: 'Nombre',
                  hint: 'Juan',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresá tu nombre'
                      : null,
                ),
                SizedBox(height: AppSpacing.md),
                AppInput(
                  controller: _surnameController,
                  label: 'Apellido',
                  hint: 'Pérez',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresá tu apellido'
                      : null,
                ),
                SizedBox(height: AppSpacing.md),
                AppInput(
                  controller: _emailController,
                  label: 'Correo electrónico',
                  hint: 'juan@ejemplo.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) => v != null &&
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(v.trim())
                      ? null
                      : 'Ingresá un correo electrónico válido',
                ),
                SizedBox(height: AppSpacing.md),
                AppInput(
                  controller: _passwordController,
                  label: 'Contraseña',
                  hint: '8+ caracteres, con letras y números',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != null &&
                          v.length >= 8 &&
                          RegExp(r'[A-Za-záéíóúÁÉÍÓÚñÑ]').hasMatch(v) &&
                          RegExp(r'\d').hasMatch(v)
                      ? null
                      : 'Usá al menos 8 caracteres, letras y números',
                ),
                SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: 'Continuar',
                  onPressed: _busy ? null : _continueToIdentity,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        _buildSocialRegistration(),
      ],
    );
  }

  Widget _buildIdentityStep() {
    return AppCard(
      key: const ValueKey('register-identity-step'),
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _identityFormKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel('Identidad y contacto'),
            SizedBox(height: AppSpacing.md),
            AppInput(
              controller: _dniController,
              label: 'DNI',
              hint: '12345678',
              prefixIcon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                return RegExp(r'^\d{7,8}$').hasMatch(digits)
                    ? null
                    : 'Ingresá 7 u 8 dígitos';
              },
            ),
            SizedBox(height: AppSpacing.md),
            Semantics(
              button: true,
              label: 'Elegir fecha de nacimiento',
              child: GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: AppInput(
                    controller: _dateController,
                    label: 'Fecha de nacimiento',
                    hint: 'DD/MM/AAAA',
                    prefixIcon: Icons.calendar_today_outlined,
                    validator: (_) =>
                        _selectedDate == null ? 'Seleccioná una fecha' : null,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            AppInput(
              controller: _whatsappController,
              label: 'WhatsApp',
              hint: '+54 9 11 1234 5678',
              prefixIcon: Icons.chat_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: validateWhatsAppNumber,
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.secondary,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Tu WhatsApp solo se comparte con la otra persona cuando una clase queda confirmada.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Crear cuenta',
              onPressed: _busy ? null : _submit,
            ),
            SizedBox(height: AppSpacing.sm),
            AppButton(
              text: 'Volver',
              type: AppButtonType.ghost,
              onPressed: _busy ? null : _goBack,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialRegistration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppColors.divider.withValues(alpha: 0.6),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('o registrate con', style: AppTextStyles.caption),
            ),
            Expanded(
              child: Divider(
                color: AppColors.divider.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        AppButton(
          text: 'Continuar con Google',
          type: AppButtonType.outline,
          icon: Icons.g_mobiledata_rounded,
          onPressed: _busy ? null : _loginWithGoogle,
        ),
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
          SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Continuar con Apple',
            type: AppButtonType.outline,
            icon: Icons.apple,
            onPressed: _busy ? null : _loginWithApple,
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFlowProgress(
          label: 'ETAPA 1 DE 3 · CUENTA · PASO ${_step + 1} DE 2',
          value: _step == 0 ? 1 / 6 : 1 / 3,
        ),
        SizedBox(height: AppSpacing.xl),
        Hero(
          tag: 'manejapp_logo_register',
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.sm,
              image: const DecorationImage(
                image: AssetImage(AppAssets.logo),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(
          _step == 0 ? 'Creá tu cuenta' : 'Completá tus datos',
          style: AppTextStyles.displayMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          _step == 0
              ? 'Empezá con tus datos de acceso. Te va a llevar menos de un minuto.'
              : 'Necesitamos validar tu identidad y guardar un contacto seguro para tus clases.',
          style: AppTextStyles.bodyNormal.copyWith(fontSize: 15, height: 1.45),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
