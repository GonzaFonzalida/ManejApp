import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/utils/instructor_activation_client_status.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/role_router.dart';
import 'package:manejapp/utils/whatsapp.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/app_flow_progress.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/next_action_card.dart';
import 'package:manejapp/widgets/skeleton_loader.dart';

import 'complete_instructor_profile_screen.dart';
import 'editar_perfil_screen.dart';
import 'instructor_dashboard_screen.dart';
import 'instructor_registration_docs_screen.dart';

const _secureStorage = appSecureStorage;

/// Clave por usuario: último `activationClientStatus` conocido (transición → celebración one-time).
String _activationStatusStorageKey(String userId) =>
    'instructor_activation_last_client_status_$userId';

/// Hub unificado de onboarding instructor: verificación + perfil + activación.
class InstructorOnboardingHubScreen extends StatefulWidget {
  static const routeName = '/instructor_onboarding_hub';

  const InstructorOnboardingHubScreen({super.key});

  @override
  State<InstructorOnboardingHubScreen> createState() =>
      _InstructorOnboardingHubScreenState();
}

class _InstructorOnboardingHubScreenState
    extends State<InstructorOnboardingHubScreen> {
  static const _docKeys = <String>[
    'dobleComandoImg',
    'seguroImg',
    'vtvImg',
    'reincidenciaImg',
    'licenciaImg',
  ];

  static const Map<String, String> _docLabels = {
    'dobleComandoImg': 'Doble comando',
    'seguroImg': 'Seguro de autoescuela',
    'vtvImg': 'Verificación técnica (VTV)',
    'reincidenciaImg': 'Certificado de reincidencia',
    'licenciaImg': 'Licencia vigente',
  };

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _mpStatus;
  bool _mpConnecting = false;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;
  bool _celebrationInFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _showReadyCelebration() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: AppColors.surfaceLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Listo para recibir reservas',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tu perfil cumple documentación, cuenta y visibilidad pública. Los alumnos pueden reservarte; desde el panel gestionás clases y disponibilidad.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyNormal.copyWith(
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    text: 'Ir a mi panel',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final p = await ApiService.getInstructorMeOrNull();
      Map<String, dynamic>? mpStatus;
      try {
        mpStatus = await ApiService.getInstructorMercadoPagoStatus();
      } catch (_) {
        mpStatus = null;
      }
      if (!mounted) return;
      setState(() {
        _profile = p;
        _mpStatus = mpStatus;
        _loading = false;
        _error = null;
      });
      final target = await RoleRouter.resolveRouteForCurrentUser(
        context: 'instructor_hub_poll',
      );
      if (!mounted) return;
      if (target == InstructorDashboardScreen.routeName) {
        final userId = await _secureStorage.read(key: 'user_id');
        final activation = instructorActivationClientStatus(p);

        if (userId != null && userId.isNotEmpty) {
          final key = _activationStatusStorageKey(userId);
          final last = await _secureStorage.read(key: key);
          final shouldCelebrate = activation == 'active' &&
              last != 'active' &&
              !_celebrationInFlight;

          if (activation != 'active') {
            await _secureStorage.write(key: key, value: activation);
          } else if (shouldCelebrate) {
            _celebrationInFlight = true;
            await _secureStorage.write(key: key, value: 'active');
            try {
              await _showReadyCelebration();
            } finally {
              _celebrationInFlight = false;
            }
          }
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(target);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = humanizeApiError(e);
      });
    }
  }

  List<_DocRow> _docRows() {
    final p = _profile;
    if (p == null) return [];
    final reviews = p['documentReviews'];
    final Map<String, dynamic>? byKey = reviews is List
        ? {
            for (final r in reviews)
              if (r is Map<String, dynamic> && r['documentType'] != null)
                r['documentType'].toString(): r,
          }
        : null;

    return _docKeys.map((key) {
      final url = p[key]?.toString();
      final hasFile = url != null && url.isNotEmpty;
      final row = byKey?[key];
      final statusStr = row?['status']?.toString().toUpperCase();
      var reason = row?['rejectionReason']?.toString();
      final expiresAt = DateTime.tryParse(row?['expiresAt']?.toString() ?? '');
      final expired = statusStr == 'APPROVED' &&
          expiresAt != null &&
          expiresAt.isBefore(DateTime.now());

      _DocUiStatus ui;
      if (!hasFile) {
        ui = _DocUiStatus.missing;
      } else if (statusStr == 'REJECTED' || expired) {
        ui = _DocUiStatus.actionRequired;
        if (expired) {
          reason = 'El documento está vencido. Subí una versión vigente.';
        }
      } else if (statusStr == 'APPROVED') {
        ui = _DocUiStatus.approved;
      } else if (statusStr == 'PENDING_REVIEW' ||
          statusStr == 'MISSING' ||
          statusStr == null) {
        // Solo `documentReviews` + archivo; nunca mezclar con `isValid` (cuenta admin).
        ui = _DocUiStatus.pendingReview;
      } else {
        ui = _DocUiStatus.pendingReview;
      }

      return _DocRow(
        key: key,
        label: _docLabels[key] ?? key,
        status: ui,
        rejectionReason: reason,
      );
    }).toList();
  }

  String _profileTaskLabel(String id) {
    switch (id) {
      case 'experience_years':
        return 'Años de experiencia';
      case 'profile_photo':
        return 'Foto de perfil';
      case 'bio':
        return 'Descripción profesional';
      case 'service_zone':
        return 'Zona en el mapa';
      case 'hourly_rate':
        return 'Precio por hora (> 0)';
      case 'whatsapp_number':
        return 'WhatsApp de contacto';
      default:
        return id;
    }
  }

  /// Track 2: solo perfil profesional (sin visibilidad). Preferí `onboarding` del backend si viene en `/me`.
  List<_ProfileTask> _profileTasks() {
    final p = _profile;
    if (p == null) return [];
    final ob = p['onboarding'];
    if (ob is Map) {
      final pt = ob['profileTrack'];
      if (pt is Map) {
        final items = pt['items'];
        if (items is List) {
          final out = <_ProfileTask>[];
          for (final e in items) {
            if (e is! Map) continue;
            final id = e['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            final done = e['done'] == true;
            out.add(
                _ProfileTask(id, _profileTaskLabel(id), done, essential: true));
          }
          if (out.isNotEmpty) return out;
        }
      }
    }

    final exp = p['experienceYears'];
    final lat = p['lat'];
    final lng = p['lng'];
    final bio = p['bio']?.toString().trim();
    final hourly = p['hourlyRate'];
    final okHourly = hourly is num
        ? hourly > 0
        : () {
            final v = double.tryParse(hourly?.toString() ?? '');
            return v != null && v > 0;
          }();

    final okExp = exp is num || int.tryParse(exp?.toString() ?? '') != null;
    final okZone = lat is num && lng is num;
    final okBio = bio != null && bio.isNotEmpty;
    final okPhoto = RoleRouter.hasInstructorProfilePhoto(p);
    final user = p['user'];
    final phone = user is Map ? user['phoneNumber']?.toString() : null;
    final okWhatsApp = normalizeWhatsAppNumber(phone) != null;

    return [
      _ProfileTask('experience_years', 'Años de experiencia', okExp,
          essential: true),
      _ProfileTask('profile_photo', 'Foto de perfil', okPhoto, essential: true),
      _ProfileTask('bio', 'Descripción profesional', okBio, essential: true),
      _ProfileTask('service_zone', 'Zona en el mapa', okZone, essential: true),
      _ProfileTask('hourly_rate', 'Precio por hora (> 0)', okHourly,
          essential: true),
      _ProfileTask('whatsapp_number', 'WhatsApp de contacto', okWhatsApp,
          essential: true),
    ];
  }

  Future<void> _openProfessionalProfileSection([String? initialSection]) async {
    await Navigator.pushNamed(
      context,
      CompleteInstructorProfileScreen.routeName,
      arguments:
          initialSection != null ? {'initialSection': initialSection} : null,
    );
    if (mounted) _load();
  }

  Future<void> _openEditarPerfil() async {
    await Navigator.pushNamed(context, EditarPerfilScreen.routeName);
    if (mounted) _load();
  }

  Future<void> _openDocs({String? focusDocKey}) async {
    await Navigator.pushNamed(
      context,
      InstructorRegistrationDocsScreen.routeName,
      arguments: focusDocKey != null ? {'focusDocKey': focusDocKey} : null,
    );
    if (mounted) _load();
  }

  bool _hasActiveCar() {
    final cars = _profile?['cars'];
    return cars is List &&
        cars.any((car) => car is Map && car['isActive'] == true);
  }

  Future<void> _openCar() async {
    await Navigator.pushNamed(context, '/instructor_car');
    if (mounted) _load();
  }

  Future<void> _connectMercadoPago() async {
    if (_mpConnecting) return;
    setState(() => _mpConnecting = true);
    try {
      final url = await ApiService.getInstructorMercadoPagoConnectUrl();
      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        AppFeedback.showError(context, 'No pudimos abrir Mercado Pago');
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _mpConnecting = false);
    }
  }

  Widget _buildMercadoPagoCard() {
    final connected = _mpStatus?['connected'] == true;
    final collectorId = _mpStatus?['mpCollectorId']?.toString();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'COBROS',
            style: AppTextStyles.bodyNormal.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            connected
                ? 'Mercado Pago conectado${collectorId != null && collectorId.isNotEmpty ? ' (ID $collectorId)' : ''}.'
                : 'Conectá tu cuenta de Mercado Pago para recibir pagos de tus clases.',
            style: AppTextStyles.bodyNormal.copyWith(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (!connected)
            AppButton(
              text: _mpConnecting ? 'Abriendo…' : 'Conectar Mercado Pago',
              icon: Icons.account_balance_wallet_outlined,
              onPressed: _mpConnecting ? null : _connectMercadoPago,
            ),
        ],
      ),
    );
  }

  Widget _buildCarCard() {
    final ready = _hasActiveCar();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'VEHÍCULO',
            style: AppTextStyles.bodyNormal.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ready
                ? 'Tenés un vehículo activo para brindar las clases.'
                : 'Cargá el vehículo que vas a usar. Debe estar activo antes de recibir reservas.',
            style: AppTextStyles.bodyNormal.copyWith(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          AppButton(
            text: ready ? 'Gestionar vehículo' : 'Cargar vehículo',
            type: ready ? AppButtonType.secondary : AppButtonType.primary,
            icon: Icons.directions_car_outlined,
            onPressed: _openCar,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextStepCard = _buildNextStepCard();
    final docs = _docRows();
    final profileTasks = _profileTasks();
    final docsApproved =
        docs.where((row) => row.status == _DocUiStatus.approved).length;
    final docsNeedAttention = docs.any((row) =>
        row.status == _DocUiStatus.missing ||
        row.status == _DocUiStatus.actionRequired);
    final profileDone = profileTasks.where((task) => task.done).length;
    final profileIncomplete = profileTasks.any((task) => !task.done);
    final carReady = _hasActiveCar();
    final paymentsReady = _mpStatus?['connected'] == true;
    final operationDone = (carReady ? 1 : 0) + (paymentsReady ? 1 : 0);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Cuenta instructor',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _loading && _profile == null
          ? const Center(child: CardSkeletonLoader())
          : _error != null && _profile == null
              ? Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: AppErrorState(
                      title: 'No pudimos cargar tu cuenta',
                      message: _error,
                      onRetry: () => _load(),
                    ),
                  ),
                )
              : SafeArea(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _load(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProgressHeader(),
                          if (nextStepCard != null) ...[
                            const SizedBox(height: 16),
                            nextStepCard,
                          ],
                          const SizedBox(height: 28),
                          Text(
                            'Todos tus requisitos',
                            style: AppTextStyles.heading.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Abrí una sección solo cuando necesites ver o cambiar sus detalles.',
                            style:
                                AppTextStyles.bodyNormal.copyWith(height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          _buildExpandableSection(
                            storageKey: 'instructor-documents',
                            icon: Icons.verified_user_outlined,
                            title: 'Documentación',
                            subtitle:
                                '$docsApproved de ${docs.length} documentos aprobados',
                            completed:
                                docs.isNotEmpty && docsApproved == docs.length,
                            initiallyExpanded: docsNeedAttention,
                            children: [
                              ...docs.map(_buildDocTile),
                              AppButton(
                                text: 'Gestionar documentación',
                                type: AppButtonType.outline,
                                icon: Icons.folder_outlined,
                                onPressed: () => _openDocs(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildExpandableSection(
                            storageKey: 'instructor-profile',
                            icon: Icons.badge_outlined,
                            title: 'Perfil profesional',
                            subtitle:
                                '$profileDone de ${profileTasks.length} datos completos',
                            completed: profileTasks.isNotEmpty &&
                                profileDone == profileTasks.length,
                            initiallyExpanded:
                                !docsNeedAttention && profileIncomplete,
                            children: [
                              ...profileTasks.map(_buildProfileTile),
                              const SizedBox(height: 8),
                              AppButton(
                                text: 'Editar nombre y WhatsApp',
                                type: AppButtonType.outline,
                                icon: Icons.contact_page_outlined,
                                onPressed: _openEditarPerfil,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildExpandableSection(
                            storageKey: 'instructor-operation',
                            icon: Icons.car_repair_outlined,
                            title: 'Vehículo y cobros',
                            subtitle:
                                '$operationDone de 2 configuraciones listas',
                            completed: carReady && paymentsReady,
                            initiallyExpanded: !docsNeedAttention &&
                                !profileIncomplete &&
                                (!carReady || !paymentsReady),
                            children: [
                              _buildCarCard(),
                              const SizedBox(height: 12),
                              _buildMercadoPagoCard(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildExpandableSection(
                            storageKey: 'instructor-publication',
                            icon: Icons.public_outlined,
                            title: 'Publicación',
                            subtitle: _profile?['isListed'] == true
                                ? 'Tu perfil está visible para alumnos'
                                : 'Tu perfil todavía no está visible',
                            completed: _profile?['isListed'] == true,
                            initiallyExpanded: carReady &&
                                paymentsReady &&
                                _profile?['isListed'] != true,
                            children: [
                              _buildActivationCard(),
                              const SizedBox(height: 12),
                              _buildPublicationListingCard(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildExpandableSection({
    required String storageKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool completed,
    required bool initiallyExpanded,
    required List<Widget> children,
  }) {
    final accent = completed ? AppColors.success : AppColors.primary;
    return AppCard(
      padding: EdgeInsets.zero,
      variant: AppCardVariant.outlined,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>(storageKey),
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          title: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(subtitle, style: AppTextStyles.bodySmall),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (completed) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
                const SizedBox(width: 4),
              ],
              Icon(Icons.expand_more_rounded, color: accent),
            ],
          ),
          children: children,
        ),
      ),
    );
  }

  String _publishReasonLabel(String code) {
    switch (code) {
      case 'account_not_valid':
        return 'Cuenta sin aprobar por el equipo';
      case 'not_listed':
        return 'Activá visibilidad para alumnos';
      case 'missing_profile_image':
        return 'Foto de perfil en tu cuenta';
      case 'missing_bio':
        return 'Descripción profesional';
      case 'missing_hourly_rate':
      case 'invalid_hourly_rate':
        return 'Precio por hora válido';
      case 'missing_location':
        return 'Zona en el mapa';
      case 'missing_experience':
        return 'Años de experiencia';
      case 'missing_whatsapp':
        return 'WhatsApp válido con código de país';
      case 'document_missing_file':
        return 'Documentación obligatoria completa';
      case 'document_not_approved':
        return 'Documentos aprobados por el equipo';
      case 'document_rejected':
        return 'Corregir documentos rechazados';
      case 'document_pending_review':
        return 'Documentos en revisión';
      case 'document_expired':
        return 'Actualizar documentos vencidos';
      case 'mercadopago_not_connected':
        return 'Conectar Mercado Pago';
      case 'missing_active_car':
        return 'Cargar un vehículo activo';
      default:
        return code;
    }
  }

  Widget? _buildNextStepCard() {
    final p = _profile;
    if (p == null) return null;

    final rejected = _docRows()
        .where((row) => row.status == _DocUiStatus.actionRequired)
        .toList();
    if (rejected.isNotEmpty) {
      final row = rejected.first;
      return NextActionCard(
        priority: NextActionPriority.urgent,
        icon: Icons.error_outline_rounded,
        title: 'Corregí ${row.label}',
        description: row.rejectionReason?.trim().isNotEmpty == true
            ? row.rejectionReason!.trim()
            : 'Subí una versión nueva y legible para que podamos revisarla.',
        statusLabel: 'Requiere acción',
        primaryLabel: 'Subir de nuevo',
        onPrimary: () => _openDocs(focusDocKey: row.key),
      );
    }
    if (!RoleRouter.hasUploadedAllDocs(p)) {
      return NextActionCard(
        priority: NextActionPriority.high,
        icon: Icons.upload_file_rounded,
        title: 'Completá tu documentación',
        description:
            'Subí los cinco documentos obligatorios. Cada archivo queda guardado cuando lo elegís.',
        primaryLabel: 'Subir documentos',
        onPrimary: () => _openDocs(),
      );
    }
    if (_profileTasks().any((task) => !task.done)) {
      return NextActionCard(
        priority: NextActionPriority.high,
        icon: Icons.badge_outlined,
        title: 'Completá tu perfil profesional',
        description:
            'Agregá los datos que faltan para que los alumnos puedan conocerte y contactarte.',
        primaryLabel: 'Completar perfil',
        onPrimary: () => _openProfessionalProfileSection(),
      );
    }
    if (!_hasActiveCar()) {
      return NextActionCard(
        priority: NextActionPriority.high,
        icon: Icons.directions_car_outlined,
        title: 'Cargá el vehículo de tus clases',
        description:
            'Necesitamos un vehículo activo antes de que puedas recibir reservas.',
        primaryLabel: 'Cargar vehículo',
        onPrimary: _openCar,
      );
    }
    if (_mpStatus?['connected'] != true) {
      return NextActionCard(
        priority: NextActionPriority.standard,
        icon: Icons.account_balance_wallet_outlined,
        title: 'Conectá Mercado Pago',
        description:
            'Vinculá tu cuenta para poder recibir los pagos de tus clases.',
        primaryLabel:
            _mpConnecting ? 'Abriendo Mercado Pago…' : 'Conectar Mercado Pago',
        onPrimary: _connectMercadoPago,
      );
    }
    if (p['publishable'] != true) {
      return NextActionCard(
        priority: NextActionPriority.calm,
        icon: Icons.fact_check_outlined,
        title: 'Estamos revisando tu cuenta',
        description:
            'Ya completaste tus tareas. Te vamos a avisar cuando la aprobación esté lista.',
        statusLabel: 'En revisión',
        primaryLabel: 'Actualizar estado',
        onPrimary: () => _load(),
      );
    }
    if (p['isListed'] != true) {
      return NextActionCard(
        priority: NextActionPriority.standard,
        icon: Icons.visibility_outlined,
        title: 'Activá tu visibilidad',
        description:
            'Tu cuenta ya puede aparecer en búsquedas. Activá la visibilidad para empezar a recibir reservas.',
        primaryLabel: 'Activar visibilidad',
        onPrimary: () => _openProfessionalProfileSection('visibility'),
      );
    }
    return null;
  }

  Widget _buildProgressHeader() {
    final docs = _docRows();
    final profileTasks = _profileTasks();
    final stages = <({String label, bool done})>[
      (
        label: 'Documentación',
        done: docs.isNotEmpty &&
            docs.every((row) => row.status == _DocUiStatus.approved),
      ),
      (
        label: 'Perfil profesional',
        done:
            profileTasks.isNotEmpty && profileTasks.every((task) => task.done),
      ),
      (
        label: 'Vehículo y cobros',
        done: _hasActiveCar() && _mpStatus?['connected'] == true,
      ),
      (
        label: 'Revisión y publicación',
        done: _profile?['isListed'] == true,
      ),
    ];
    final completed = stages.where((stage) => stage.done).length;
    String? nextLabel;
    for (final stage in stages) {
      if (!stage.done) {
        nextLabel = stage.label;
        break;
      }
    }
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFlowProgress(
            label: 'ETAPA 3 DE 3 · PREPARÁ TU CUENTA DE INSTRUCTOR',
            value: (2 + completed / stages.length) / 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '$completed de ${stages.length} etapas completas',
            style:
                AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            nextLabel == null
                ? 'Tu cuenta está lista y visible para los alumnos.'
                : 'Siguiente etapa: $nextLabel.',
            style: AppTextStyles.bodyNormal.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completed / stages.length,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLighter,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Te vamos a avisar cuando tengas una nueva reserva o cambie el estado de tu aprobación.',
            style: AppTextStyles.bodyNormal.copyWith(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile(_DocRow row) {
    final icon = switch (row.status) {
      _DocUiStatus.missing => Icons.upload_file_outlined,
      _DocUiStatus.pendingReview => Icons.hourglass_top_outlined,
      _DocUiStatus.approved => Icons.verified_outlined,
      _DocUiStatus.actionRequired => Icons.error_outline,
    };
    final color = switch (row.status) {
      _DocUiStatus.missing => AppColors.textSecondary,
      _DocUiStatus.pendingReview => AppColors.warning,
      _DocUiStatus.approved => AppColors.success,
      _DocUiStatus.actionRequired => AppColors.error,
    };
    final subtitle = switch (row.status) {
      _DocUiStatus.missing => 'Todavía no subiste este archivo',
      _DocUiStatus.pendingReview => 'En revisión por el equipo',
      _DocUiStatus.approved => 'Aprobado',
      _DocUiStatus.actionRequired =>
        row.rejectionReason != null && row.rejectionReason!.trim().isNotEmpty
            ? 'Rechazado · ${row.rejectionReason!.trim()}'
            : 'Rechazado · subí una versión nueva',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: row.status == _DocUiStatus.missing ||
                  row.status == _DocUiStatus.actionRequired
              ? () => _openDocs(focusDocKey: row.key)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyNormal
                            .copyWith(fontSize: 12, height: 1.3),
                      ),
                      if (row.status == _DocUiStatus.actionRequired) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tocá para subir de nuevo',
                          style: AppTextStyles.bodyNormal.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (row.status == _DocUiStatus.missing ||
                    row.status == _DocUiStatus.actionRequired)
                  Icon(Icons.chevron_right,
                      color: AppColors.textSecondary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic>? _listingPayloadFromApi() {
    final p = _profile;
    if (p == null) return null;
    final ob = p['onboarding'];
    if (ob is! Map) return null;
    final at = ob['activationTrack'];
    if (at is! Map) return null;
    final l = at['listing'];
    if (l is! Map) return null;
    return Map<String, dynamic>.from(l);
  }

  Widget _buildPublicationListingCard() {
    final p = _profile;
    if (p == null) return const SizedBox.shrink();
    final listing = _listingPayloadFromApi();
    final listed = listing?['isListed'] == true;
    final canEnable = listing?['canEnablePublicListing'] == true;
    final reasons = listing?['reasonsBlockingListing'];
    final reasonList = reasons is List
        ? reasons.map((e) => e.toString()).toList()
        : <String>[];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publicación y visibilidad',
            style:
                AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            listed
                ? 'Tu perfil está visible para alumnos (listado activo).'
                : canEnable
                    ? 'Ya podés activar la visibilidad en búsquedas. Abrí “Visibilidad” arriba o completá el interruptor en perfil profesional.'
                    : 'El listado público sigue bloqueado hasta cumplir documentación, perfil y cuenta. No bloquea que edites tu perfil.',
            style:
                AppTextStyles.bodyNormal.copyWith(fontSize: 13, height: 1.35),
          ),
          if (!listed && reasonList.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Motivos que impiden publicar aún:',
              style: AppTextStyles.bodyNormal
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            ...reasonList.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${_publishReasonLabel(c)}',
                    style: AppTextStyles.bodyNormal.copyWith(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileTile(_ProfileTask t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProfessionalProfileSection(t.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  t.done
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: t.done ? AppColors.success : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.label + (t.essential ? '' : ' (recomendado)'),
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: t.done
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivationCard() {
    final p = _profile;
    if (p == null) return const SizedBox.shrink();
    final hasDocs = RoleRouter.hasUploadedAllDocs(p);
    final basicsComplete = RoleRouter.isInstructorProfileBasicsComplete(p);
    final valid = p['isValid'] == true;
    final listed = p['isListed'] == true;
    final publishable = RoleRouter.isInstructorPublishableFromApi(p);
    final hasRejected =
        _docRows().any((r) => r.status == _DocUiStatus.actionRequired);
    final anyDocPending =
        _docRows().any((r) => r.status == _DocUiStatus.pendingReview);

    late final IconData cardIcon;
    late final Color accent;
    late final String title;
    late final String body;

    if (hasRejected) {
      cardIcon = Icons.assignment_outlined;
      accent = AppColors.error;
      title = 'Corregí la documentación';
      body =
          'Uno o más archivos fueron rechazados. Subí versiones nuevas; el resto del proceso sigue igual.';
    } else if (!hasDocs) {
      cardIcon = Icons.folder_open_outlined;
      accent = AppColors.warning;
      title = 'Falta documentación';
      body =
          'Necesitamos los 5 documentos obligatorios para iniciar la verificación de identidad y vehículo.';
    } else if (!basicsComplete) {
      cardIcon = Icons.person_pin_circle_outlined;
      accent = AppColors.primary;
      title = 'Perfil incompleto';
      body =
          'Completá experiencia, zona en el mapa, bio, tarifa y foto. La licencia se valida con el documento que subiste. Podés seguir editando mientras revisamos la documentación.';
    } else if (anyDocPending) {
      cardIcon = Icons.fact_check_outlined;
      accent = AppColors.warning;
      title = 'Documentación en revisión';
      body =
          'El equipo revisa tus archivos en el panel de administración. Mientras tanto podés seguir afinando tu perfil.';
    } else if (!valid) {
      cardIcon = Icons.hourglass_empty_rounded;
      accent = AppColors.warning;
      title = 'Cuenta en revisión';
      body =
          'Ya enviaste lo necesario a nivel documentación. El equipo valida tu cuenta; te avisamos cuando avance el estado.';
    } else if (!publishable) {
      cardIcon = Icons.verified_outlined;
      accent = AppColors.secondary;
      title = 'Publicación pendiente';
      body =
          'Tu cuenta está aprobada. Cuando todos los documentos figuren como aprobados vas a poder activarte en búsquedas.';
    } else if (!listed) {
      cardIcon = Icons.visibility_off_outlined;
      accent = AppColors.secondary;
      title = 'Activá tu visibilidad';
      body =
          'Ya podés aparecer en búsquedas. Activá «visible para alumnos» en la pantalla de ubicación o desde tu perfil.';
    } else {
      cardIcon = Icons.rocket_launch_outlined;
      accent = AppColors.success;
      title = 'Casi listo';
      body =
          'Cumpliste los requisitos. Cuando el sistema confirme el estado, entrarás al panel de instructor automáticamente.';
    }

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(cardIcon, color: accent, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(body,
                    style: AppTextStyles.bodyNormal
                        .copyWith(height: 1.4, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _DocUiStatus { missing, pendingReview, approved, actionRequired }

class _DocRow {
  _DocRow({
    required this.key,
    required this.label,
    required this.status,
    this.rejectionReason,
  });
  final String key;
  final String label;
  final _DocUiStatus status;
  final String? rejectionReason;
}

class _ProfileTask {
  _ProfileTask(this.id, this.label, this.done, {required this.essential});
  final String id;
  final String label;
  final bool done;
  final bool essential;
}
