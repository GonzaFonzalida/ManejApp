import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../config/design_system.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import '../utils/role_router.dart';
import '../utils/user_facing_error.dart';
import '../utils/whatsapp.dart';
import '../utils/app_feedback.dart';
import '../widgets/design/app_button.dart';
import '../widgets/design/app_card.dart';
import '../widgets/design/app_input.dart';
import '../widgets/location_picker.dart';
import '../widgets/responsive_scroll_body.dart';

const _storage = appSecureStorage;

/// Argumentos opcionales al navegar con [routeName].
/// `initialSection`: id alineado con `onboarding.profileTrack.items` del backend.
class CompleteInstructorProfileScreenArgs {
  const CompleteInstructorProfileScreenArgs({this.initialSection});

  final String? initialSection;
}

/// Perfil profesional del instructor: experiencia, bio, tarifa, zona, visibilidad y foto.
/// La licencia se valida con documentación (`licenciaImg`), no con número manual.
/// La documentación no bloquea estos datos; `isListed` se habilita cuando el backend confirma los requisitos.
/// Guardado parcial: podés guardar bio/tarifa/experiencia sin tener aún la zona en el mapa.
class CompleteInstructorProfileScreen extends StatefulWidget {
  static const routeName = '/complete_instructor_profile';

  const CompleteInstructorProfileScreen({super.key});

  @override
  State<CompleteInstructorProfileScreen> createState() =>
      _CompleteInstructorProfileScreenState();
}

class _CompleteInstructorProfileScreenState
    extends State<CompleteInstructorProfileScreen> {
  static const _argInitialSection = 'initialSection';

  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _keyCoreFields = GlobalKey();
  final _keyPhoto = GlobalKey();
  final _keyZone = GlobalKey();
  final _keyVisibility = GlobalKey();

  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _hourlyController = TextEditingController();
  final _whatsappController = TextEditingController();

  double? _selectedLat;
  double? _selectedLng;

  bool _isListed = false;
  bool _canEnablePublicListing = false;
  bool _profileLoading = true;
  bool _isLoading = false;
  bool _uploadingPhoto = false;
  String? _userId;
  String? _routeInitialSection;
  bool _didScrollToSection = false;

  @override
  void initState() {
    super.initState();
    _loadInstructorSnapshot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args[_argInitialSection] is String) {
      _routeInitialSection = args[_argInitialSection] as String;
    } else if (args is CompleteInstructorProfileScreenArgs) {
      _routeInitialSection = args.initialSection;
    }
  }

  Future<void> _loadInstructorSnapshot() async {
    try {
      final uid = await _storage.read(key: 'user_id');
      final me = await ApiService.getInstructorMeOrNull();
      if (!mounted) return;
      setState(() {
        _profileLoading = false;
        _userId = uid;
        if (me != null) {
          _isListed = me['isListed'] == true;
          final onboarding = me['onboarding'];
          final activation =
              onboarding is Map ? onboarding['activationTrack'] : null;
          final listing = activation is Map ? activation['listing'] : null;
          _canEnablePublicListing = _isListed ||
              (listing is Map && listing['canEnablePublicListing'] == true);
          final at = me['addressText']?.toString();
          if (at != null && at.isNotEmpty) {
            _addressController.text = at;
          }
          _experienceController.text = me['experienceYears']?.toString() ?? '';
          _bioController.text = me['bio']?.toString() ?? '';
          final hr = me['hourlyRate'];
          _hourlyController.text = hr != null ? hr.toString() : '';
          final user = me['user'];
          if (user is Map) {
            _whatsappController.text = user['phoneNumber']?.toString() ?? '';
          }
          final lat = me['lat'];
          final lng = me['lng'];
          if (lat is num && lng is num) {
            _selectedLat = lat.toDouble();
            _selectedLng = lng.toDouble();
          }
        }
      });
    } catch (_) {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  void _maybeScrollToInitialSection() {
    if (_didScrollToSection || _profileLoading) return;
    final id = _routeInitialSection;
    if (id == null || id.isEmpty) return;
    _didScrollToSection = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final GlobalKey? key;
      switch (id) {
        case 'profile_photo':
          key = _keyPhoto;
          break;
        case 'experience_years':
        case 'bio':
        case 'hourly_rate':
        case 'whatsapp_number':
          key = _keyCoreFields;
          break;
        case 'service_zone':
          key = _keyZone;
          break;
        case 'visibility':
          key = _keyVisibility;
          break;
        default:
          key = _keyCoreFields;
      }
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _hourlyController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_userId == null || _userId!.isEmpty) {
      AppFeedback.showError(
          context, 'No encontramos tu usuario. Volvé a iniciar sesión.');
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 88);
    if (file == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      await ApiService.uploadProfileImage(_userId!, file);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Foto de perfil actualizada');
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  /// PUT con solo los campos válidos presentes. No exige mapa si no enviás `lat`/`lng`.
  Future<void> _submit() async {
    if (_isLoading) return;

    final body = <String, dynamic>{};

    final whatsappError = validateWhatsAppNumber(_whatsappController.text);
    if (whatsappError != null) {
      AppFeedback.showError(context, whatsappError);
      return;
    }
    body['whatsappNumber'] = normalizeWhatsAppNumber(_whatsappController.text)!;

    final expRaw = _experienceController.text.trim();
    if (expRaw.isNotEmpty) {
      final exp = int.tryParse(expRaw);
      if (exp == null || exp < 0 || exp > 50) {
        AppFeedback.showError(
            context, 'Ingresá una cantidad de años entre 0 y 50');
        return;
      }
      body['experienceYears'] = exp;
    }

    final bio = _bioController.text.trim();
    if (bio.isNotEmpty) {
      body['bio'] = bio;
    }

    final hourlyRaw = _hourlyController.text.trim();
    if (hourlyRaw.isNotEmpty) {
      final hourly = double.tryParse(hourlyRaw.replaceAll(',', '.'));
      if (hourly == null || hourly <= 0) {
        AppFeedback.showError(
            context, 'Ingresá un precio por hora mayor que cero');
        return;
      }
      body['hourlyRate'] = hourly;
    }

    final hasLocation = _selectedLat != null && _selectedLng != null;
    if (hasLocation) {
      final addr = _addressController.text.trim();
      if (addr.isEmpty) {
        AppFeedback.showError(
            context, 'Ingresá un nombre para tu ubicación en el mapa');
        return;
      }
      body['addressText'] = addr;
      body['lat'] = _selectedLat;
      body['lng'] = _selectedLng;
    }

    if (_canEnablePublicListing) {
      body['isListed'] = _isListed;
    }

    if (body.isEmpty) {
      AppFeedback.showInfo(context, 'No hay cambios para guardar');
      return;
    }

    setState(() => _isLoading = true);
    try {
      developer.log(
          '[CompleteInstructorProfile] submit keys=${body.keys.toList()}',
          name: 'RoleRouter');
      await ApiService.updateInstructorMe(body);
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Cambios guardados');
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        final target = await RoleRouter.resolveRouteForCurrentUser(
          context: 'complete_instructor_profile(afterSave)',
        );
        developer.log('[CompleteInstructorProfile] → $target',
            name: 'RoleRouter');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, target);
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _maybeScrollToInitialSection();

    final initial = _selectedLat != null && _selectedLng != null
        ? LatLng(_selectedLat!, _selectedLng!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Perfil profesional',
            style: AppTextStyles.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: SafeArea(
        child: _profileLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Datos profesionales',
                        style:
                            AppTextStyles.displayLarge.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Podés guardar en cualquier momento: la documentación en revisión no bloquea estos datos. '
                        'Tu WhatsApp es obligatorio y solo se comparte con alumnos que tengan una clase confirmada. '
                        'Podés guardar texto y tarifa sin tener aún la zona en el mapa. '
                        'La visibilidad pública solo se activa cuando el sistema marque tu cuenta como publicable.',
                        style: AppTextStyles.bodyNormal.copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 28),
                      KeyedSubtree(
                        key: _keyCoreFields,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppInput(
                              label: 'WhatsApp de contacto',
                              hint: '+54 9 11 1234 5678',
                              controller: _whatsappController,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.chat_outlined,
                              validator: validateWhatsAppNumber,
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Años de experiencia',
                              hint: '0 a 50',
                              controller: _experienceController,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.timelapse_outlined,
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Descripción profesional',
                              hint:
                                  'Contá tu experiencia y estilo de enseñanza',
                              controller: _bioController,
                              maxLines: 4,
                              prefixIcon: Icons.article_outlined,
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 16),
                            AppInput(
                              label: 'Precio por hora',
                              hint: 'Ej. 15000',
                              controller: _hourlyController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              prefixIcon: Icons.payments_outlined,
                              validator: (_) => null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      KeyedSubtree(
                        key: _keyPhoto,
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Foto de perfil',
                                style: AppTextStyles.bodyLarge
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'La usan los alumnos para reconocerte. Se sube a tu cuenta de usuario.',
                                style: AppTextStyles.bodyNormal
                                    .copyWith(fontSize: 13, height: 1.35),
                              ),
                              const SizedBox(height: 14),
                              AppButton(
                                text: _uploadingPhoto
                                    ? 'Subiendo…'
                                    : 'Elegir foto de perfil',
                                type: AppButtonType.secondary,
                                icon: Icons.photo_camera_outlined,
                                isLoading: _uploadingPhoto,
                                onPressed: _uploadingPhoto
                                    ? null
                                    : _pickAndUploadPhoto,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      KeyedSubtree(
                        key: _keyZone,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Zona en el mapa',
                              style:
                                  AppTextStyles.heading.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 12),
                            AppInput(
                              label: 'Nombre de la ubicación',
                              hint: 'ej. Zona Norte, Belgrano',
                              controller: _addressController,
                              prefixIcon: Icons.store_mall_directory,
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 16),
                            AppCard(
                              padding: EdgeInsets.zero,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: SizedBox(
                                  height: ResponsiveLayout.embeddedMapHeight(
                                      context),
                                  child: LocationPicker(
                                    initialCenter: initial,
                                    onLocationChanged: (loc, address) {
                                      setState(() {
                                        _selectedLat = loc.latitude;
                                        _selectedLng = loc.longitude;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      KeyedSubtree(
                        key: _keyVisibility,
                        child: _canEnablePublicListing
                            ? AppCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: SwitchListTile(
                                  value: _isListed,
                                  activeThumbColor: AppColors.primary,
                                  tileColor: Colors.transparent,
                                  onChanged: _isLoading
                                      ? null
                                      : (v) => setState(() => _isListed = v),
                                  title: Text(
                                    'Visible en búsquedas de alumnos',
                                    style: AppTextStyles.bodyLarge
                                        .copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Solo disponible cuando cumplís todos los requisitos de publicación.',
                                    style: AppTextStyles.bodyNormal
                                        .copyWith(fontSize: 12),
                                  ),
                                ),
                              )
                            : AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: AppColors.textSecondary,
                                        size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Cuando tu perfil, vehículo, cobros y documentación estén listos, vas a poder activar la visibilidad desde acá.',
                                        style: AppTextStyles.bodyNormal
                                            .copyWith(
                                                fontSize: 13, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 36),
                      AppButton(
                        text: 'Guardar cambios',
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
