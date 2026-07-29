import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/utils/role_router.dart';
import 'package:manejapp/services/location_autocomplete_controller.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_input.dart';
import 'package:manejapp/widgets/design/app_flow_progress.dart';
import 'package:manejapp/widgets/experience_level_slider.dart';
import 'package:manejapp/utils/reservation_status_education.dart';
import 'package:manejapp/widgets/design/context_help_card.dart';
import 'package:manejapp/widgets/location_autocomplete_dropdown.dart';
import 'package:manejapp/utils/whatsapp.dart';

const _storage = appSecureStorage;

/// Onboarding en pasos cortos después de elegir rol alumno.
class StudentProgressiveOnboardingScreen extends StatefulWidget {
  static const routeName = '/student_onboarding_v1';

  final String? userId;

  const StudentProgressiveOnboardingScreen({super.key, this.userId});

  @override
  State<StudentProgressiveOnboardingScreen> createState() =>
      _StudentProgressiveOnboardingScreenState();
}

class _StudentProgressiveOnboardingScreenState
    extends State<StudentProgressiveOnboardingScreen> {
  late final PageController _pageController;
  int _page = 0;
  static const int _totalPages = 4;

  int _experienceLevel = 1;
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationAutocomplete = LocationAutocompleteController();
  XFile? _pickedImage;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    unawaited(_loadExistingWhatsApp());
  }

  Future<void> _loadExistingWhatsApp() async {
    try {
      final userId = await _resolveUserId();
      if (userId == null) return;
      final profile = await ApiService.getUserProfile(userId);
      final phone = profile['phoneNumber']?.toString();
      if (!mounted || phone == null || phone.isEmpty) return;
      _phoneController.text = phone;
    } catch (_) {
      // El usuario puede ingresarlo manualmente si la precarga falla.
    }
  }

  @override
  void dispose() {
    _locationAutocomplete.dispose();
    _pageController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<String?> _resolveUserId() async {
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      return widget.userId;
    }
    return _storage.read(key: 'user_id');
  }

  Future<void> _saveExperienceAndNext() async {
    setState(() => _busy = true);
    try {
      await ApiService.patchStudentProfile(_experienceLevel);
      if (!mounted) return;
      _nextPage();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, humanizeApiError(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _savePhoneAndNext() async {
    final validationError = validateWhatsAppNumber(_phoneController.text);
    if (validationError != null) {
      AppFeedback.showError(context, validationError);
      return;
    }
    final phone = normalizeWhatsAppNumber(_phoneController.text)!;
    setState(() => _busy = true);
    try {
      await ApiService.updateMyWhatsApp(phone);
      if (!mounted) return;
      _nextPage();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, humanizeApiError(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveLocationAndNext({required bool skip}) async {
    if (skip) {
      _nextPage();
      return;
    }
    final loc = _locationController.text.trim();
    if (loc.isNotEmpty && loc.length < 3) {
      AppFeedback.showError(context, 'Ubicación muy corta o tocá Saltar.');
      return;
    }
    if (loc.isEmpty) {
      _nextPage();
      return;
    }
    final userId = await _resolveUserId();
    if (userId == null) {
      if (!mounted) return;
      AppFeedback.showError(context, 'No se encontró tu usuario.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ApiService.updateUser(userId, {'location': loc});
      if (!mounted) return;
      _nextPage();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, humanizeApiError(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (img != null && mounted) setState(() => _pickedImage = img);
  }

  Future<void> _finishPhotoStep({required bool skip}) async {
    if (skip || _pickedImage == null) {
      await _completeOnboarding();
      return;
    }
    final userId = await _resolveUserId();
    if (userId == null) {
      if (!mounted) return;
      AppFeedback.showError(context, 'No se encontró tu usuario.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ApiService.uploadProfileImage(userId, _pickedImage!);
      if (!mounted) return;
      await _completeOnboarding();
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, humanizeApiError(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeOnboarding() async {
    final userId = await _resolveUserId();
    if (userId != null) {
      await RoleRouter.markStudentOnboardingV1CompleteFor(userId);
    }
    if (!mounted) return;
    final target = await RoleRouter.resolveRouteForCurrentUser(
        context: 'student_onboarding_done');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(target);
  }

  void _nextPage() {
    if (_page >= _totalPages - 1) return;
    HapticFeedback.selectionClick();
    _pageController.nextPage(
      duration: AppMotion.duration(context, AppDurations.normal),
      curve: AppCurves.emphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppFlowProgress(
                    label:
                        'ETAPA 3 DE 3 · PERFIL · PASO ${_page + 1} DE $_totalPages',
                    value: (2 + ((_page + 1) / _totalPages)) / 3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        'Perfil del alumno',
                        style: AppTextStyles.bodySmall,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.surfaceLight,
                                    title: Text('¿Salir del asistente?',
                                        style: AppTextStyles.heading
                                            .copyWith(fontSize: 18)),
                                    content: Text(
                                      'Podés completar tu perfil más tarde desde Inicio o Perfil. Necesitarás un WhatsApp válido antes de reservar una clase.',
                                      style: AppTextStyles.bodyNormal,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text('Seguir acá',
                                            style: TextStyle(
                                                color:
                                                    AppColors.textSecondary)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text('Salir',
                                            style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true && mounted) {
                                  await _completeOnboarding();
                                }
                              },
                        child: Text(
                          'Después',
                          style: AppTextStyles.bodyNormal
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Semantics(
                label: 'Progreso del perfil',
                value: '${_page + 1} de $_totalPages',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: (_page + 1) / _totalPages,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceLighter,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildStepWelcomeExperience(),
                  _buildStepPhone(),
                  _buildStepLocation(),
                  _buildStepPhoto(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepWelcomeExperience() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Personalizá tu experiencia',
            style: AppTextStyles.displayMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Decinos tu nivel actual de manejo. Siempre podés cambiarlo en tu perfil.',
            style: AppTextStyles.bodyNormal
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          SizedBox(height: AppSpacing.md),
          ContextHelpCard(
            title: 'Cómo reservar tu primera clase',
            steps: ReservationStatusEducation.studentBookingFlowSteps,
            icon: Icons.route_outlined,
          ),
          SizedBox(height: AppSpacing.xl),
          AppCard(
            variant: AppCardVariant.outlined,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ExperienceLevelSlider(
              embeddedOnPanel: true,
              level: _experienceLevel,
              onLevelChanged: (v) => setState(() => _experienceLevel = v),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'Continuar',
            onPressed: _busy ? null : _saveExperienceAndNext,
            isLoading: _busy,
          ),
        ],
      ),
    );
  }

  Widget _buildStepPhone() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu WhatsApp',
            style: AppTextStyles.displayMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Es obligatorio para reservar. Solo se habilita entre vos y el instructor cuando la clase está confirmada.',
            style: AppTextStyles.bodyNormal
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          SizedBox(height: AppSpacing.xl),
          AppInput(
            controller: _phoneController,
            label: 'WhatsApp con código de país',
            hint: '+54 9 11 1234 5678',
            prefixIcon: Icons.chat_outlined,
            keyboardType: TextInputType.phone,
            validator: validateWhatsAppNumber,
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Guardar y continuar',
            onPressed: _busy ? null : _savePhoneAndNext,
            isLoading: _busy,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLocation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Dónde buscás clases?',
            style: AppTextStyles.displayMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Opcional: mejoramos sugerencias de instructores en tu zona.',
            style: AppTextStyles.bodyNormal
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          SizedBox(height: AppSpacing.xl),
          AppInput(
            controller: _locationController,
            label: 'Zona o barrio',
            hint: 'Ej: Palermo, Buenos Aires',
            prefixIcon: Icons.location_on_outlined,
            onChanged: _locationAutocomplete.onQueryChanged,
          ),
          AnimatedBuilder(
            animation: _locationAutocomplete,
            builder: (context, _) {
              if (!_locationAutocomplete.showSuggestions) {
                return const SizedBox.shrink();
              }
              return LocationAutocompleteDropdown(
                isLoading: _locationAutocomplete.isLoading,
                error: _locationAutocomplete.error,
                suggestions: _locationAutocomplete.suggestions,
                hasQuery: _locationAutocomplete.hasQuery,
                onSelect: (s) {
                  _locationController.text = s['display'] ?? '';
                  _locationAutocomplete.selectSuggestion();
                },
              );
            },
          ),
          SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Guardar y continuar',
            onPressed: _busy ? null : () => _saveLocationAndNext(skip: false),
            isLoading: _busy,
          ),
          SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Saltar por ahora',
            type: AppButtonType.ghost,
            onPressed: _busy ? null : () => _saveLocationAndNext(skip: true),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPhoto() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu foto de perfil',
            style: AppTextStyles.displayMedium,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Opcional: ayuda a generar confianza al reservar.',
            style: AppTextStyles.bodyNormal
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          SizedBox(height: AppSpacing.xl),
          Center(
            child: Semantics(
              label: 'Elegir foto de perfil',
              button: true,
              child: GestureDetector(
                onTap: _busy ? null : _pickPhoto,
                child: Builder(
                  builder: (context) {
                    final photoSize = ResponsiveLayout.heroIconSize(context,
                        max: 120, min: 88);
                    return Container(
                      width: photoSize,
                      height: photoSize,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider, width: 2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedImage == null
                          ? Icon(Icons.add_a_photo_outlined,
                              size: 40, color: AppColors.textSecondary)
                          : (!kIsWeb)
                              ? Image.file(
                                  File(_pickedImage!.path),
                                  fit: BoxFit.cover,
                                  width: photoSize,
                                  height: photoSize,
                                )
                              : Icon(Icons.image_outlined,
                                  size: 40, color: AppColors.textSecondary),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton(
              onPressed: _busy ? null : _pickPhoto,
              child: Text(
                _pickedImage == null ? 'Elegir de la galería' : 'Cambiar foto',
                style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            text:
                _pickedImage == null ? 'Continuar sin foto' : 'Subir y entrar',
            onPressed: _busy
                ? null
                : () => _finishPhotoStep(skip: _pickedImage == null),
            isLoading: _busy,
          ),
          SizedBox(height: AppSpacing.md),
          if (_pickedImage != null)
            AppButton(
              text: 'Omitir foto',
              type: AppButtonType.ghost,
              onPressed: _busy ? null : () => _finishPhotoStep(skip: true),
            ),
        ],
      ),
    );
  }
}
