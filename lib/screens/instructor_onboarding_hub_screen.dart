import 'dart:async';

import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/utils/instructor_activation_client_status.dart';
import 'package:manejapp/utils/role_router.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/context_help_card.dart';
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
          final shouldCelebrate =
              activation == 'active' && last != 'active' && !_celebrationInFlight;

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
      final reason = row?['rejectionReason']?.toString();

      _DocUiStatus ui;
      if (!hasFile) {
        ui = _DocUiStatus.missing;
      } else if (statusStr == 'REJECTED') {
        ui = _DocUiStatus.actionRequired;
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
            out.add(_ProfileTask(id, _profileTaskLabel(id), done, essential: true));
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

    return [
      _ProfileTask('experience_years', 'Años de experiencia', okExp, essential: true),
      _ProfileTask('profile_photo', 'Foto de perfil', okPhoto, essential: true),
      _ProfileTask('bio', 'Descripción profesional', okBio, essential: true),
      _ProfileTask('service_zone', 'Zona en el mapa', okZone, essential: true),
      _ProfileTask('hourly_rate', 'Precio por hora (> 0)', okHourly, essential: true),
    ];
  }

  double _docUnitScore(_DocUiStatus s) {
    switch (s) {
      case _DocUiStatus.missing:
        return 0;
      case _DocUiStatus.pendingReview:
        return 0.72;
      case _DocUiStatus.approved:
        return 1;
      case _DocUiStatus.actionRequired:
        return 0.38;
    }
  }

  double _verificationFraction() {
    final rows = _docRows();
    if (rows.isEmpty) return 0;
    var sum = 0.0;
    for (final r in rows) {
      sum += _docUnitScore(r.status);
    }
    return sum / rows.length;
  }

  double _profileFraction() {
    final tasks = _profileTasks();
    if (tasks.isEmpty) return 0;
    return tasks.where((t) => t.done).length / tasks.length;
  }

  double _combinedProgress() {
    return 0.5 * _verificationFraction() + 0.5 * _profileFraction();
  }

  String _headline() {
    final p = _profile;
    if (p == null) return '';
    final rejected = _docRows().where((r) => r.status == _DocUiStatus.actionRequired).toList();
    if (rejected.isNotEmpty) {
      final r = rejected.first;
      final extra = rejected.length > 1 ? ' (y ${rejected.length - 1} más)' : '';
      final motive = (r.rejectionReason != null && r.rejectionReason!.trim().isNotEmpty)
          ? ' Motivo: ${r.rejectionReason!.trim()}'
          : '';
      return 'Tenés que actualizar «${r.label}»$extra.$motive';
    }
    final hasDocs = RoleRouter.hasUploadedAllDocs(p);
    final basicsOk = RoleRouter.isInstructorProfileBasicsComplete(p);
    final valid = p['isValid'] == true;
    final anyDocPending =
        _docRows().any((r) => r.status == _DocUiStatus.pendingReview);
    if (!hasDocs) {
      return 'Subí los 5 documentos obligatorios. Cada uno se guarda al instante cuando lo elegís.';
    }
    if (anyDocPending && !basicsOk) {
      return 'Tu documentación está en revisión. Mientras tanto, completá tu perfil (zona, bio, tarifa, foto).';
    }
    if (anyDocPending && basicsOk) {
      return 'Tu documentación está en revisión. Completá tu perfil mientras el equipo la verifica.';
    }
    if (!basicsOk) {
      return 'Completá tu perfil profesional: podés hacerlo en paralelo a la revisión de documentos.';
    }
    if (!valid) {
      return 'El equipo puede revisar tu cuenta aparte de la documentación. Mientras tanto, completá tu perfil profesional; cuando todo esté verificado, vas a poder activar la visibilidad.';
    }
    return '';
  }

  Future<void> _openProfessionalProfileSection([String? initialSection]) async {
    await Navigator.pushNamed(
      context,
      CompleteInstructorProfileScreen.routeName,
      arguments: initialSection != null ? {'initialSection': initialSection} : null,
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

  List<Widget> _buildBottomActions() {
    final p = _profile!;
    final rows = _docRows();
    final hasRejected = rows.any((r) => r.status == _DocUiStatus.actionRequired);
    final hasDocs = RoleRouter.hasUploadedAllDocs(p);
    final complete = RoleRouter.isInstructorProfileComplete(p);

    if (hasRejected) {
      final first = rows.firstWhere((r) => r.status == _DocUiStatus.actionRequired);
      return [
        AppButton(
          text: 'Corregir: ${first.label}',
          icon: Icons.upload_outlined,
          onPressed: () => _openDocs(focusDocKey: first.key),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'Ver todos los documentos',
          type: AppButtonType.secondary,
          icon: Icons.folder_outlined,
          onPressed: () => _openDocs(),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'Completar perfil profesional',
          type: AppButtonType.secondary,
          icon: Icons.person_outline,
          onPressed: () => _openProfessionalProfileSection(),
        ),
      ];
    }

    if (!hasDocs) {
      return [
        AppButton(
          text: 'Subir documentación',
          icon: Icons.upload_file_outlined,
          onPressed: () => _openDocs(),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'Completar perfil profesional',
          type: AppButtonType.secondary,
          icon: Icons.person_outline,
          onPressed: () => _openProfessionalProfileSection(),
        ),
      ];
    }

    if (!complete) {
      return [
        AppButton(
          text: 'Completar perfil profesional',
          icon: Icons.person_outline,
          onPressed: () => _openProfessionalProfileSection(),
        ),
        const SizedBox(height: 12),
        AppButton(
          text: 'Gestionar documentación',
          type: AppButtonType.secondary,
          icon: Icons.folder_outlined,
          onPressed: () => _openDocs(),
        ),
      ];
    }

    return [
      AppButton(
        text: 'Editar perfil profesional',
        icon: Icons.edit_outlined,
        onPressed: () => _openProfessionalProfileSection(),
      ),
      const SizedBox(height: 12),
      AppButton(
        text: 'Nombre y teléfono',
        type: AppButtonType.secondary,
        icon: Icons.contact_page_outlined,
        onPressed: _openEditarPerfil,
      ),
      const SizedBox(height: 12),
      AppButton(
        text: 'Gestionar documentación',
        type: AppButtonType.secondary,
        icon: Icons.folder_outlined,
        onPressed: () => _openDocs(),
      ),
    ];
  }

  Widget? _buildActionRequiredBanner() {
    final rejected = _docRows().where((r) => r.status == _DocUiStatus.actionRequired).toList();
    if (rejected.isEmpty) return null;
    final r = rejected.first;
    final reason = r.rejectionReason?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.error.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.flag_outlined, color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Acción requerida',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Documento: ${r.label}',
            style: AppTextStyles.bodyLarge.copyWith(fontSize: 15),
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Motivo del equipo:\n$reason',
              style: AppTextStyles.bodyNormal.copyWith(height: 1.4, fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Qué hacer: subí una foto o archivo nuevo, bien legible. Se reemplaza el anterior al guardar.',
            style: AppTextStyles.bodyNormal.copyWith(fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 14),
          AppButton(
            text: 'Subir de nuevo',
            icon: Icons.cloud_upload_outlined,
            onPressed: () => _openDocs(focusDocKey: r.key),
          ),
        ],
      ),
    );
  }

  Future<void> _connectMercadoPago() async {
    if (_mpConnecting) return;
    setState(() => _mpConnecting = true);
    try {
      final url = await ApiService.getInstructorMercadoPagoConnectUrl();
      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Mercado Pago')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(humanizeApiError(e))),
      );
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
              fontSize: 11,
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

  @override
  Widget build(BuildContext context) {
    final actionBanner = _buildActionRequiredBanner();
    final publishCard = _buildPublishableStatusCard();
    final nextStepCard = _buildNextStepCard();
    final headline = _headline();
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
                        const SizedBox(height: 16),
                        _buildMercadoPagoCard(),
                        const SizedBox(height: 16),
                        if (publishCard != null) ...[
                          publishCard,
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 4),
                        if (actionBanner != null) actionBanner,
                        if (nextStepCard == null && headline.isNotEmpty)
                          Text(
                            headline,
                            style: AppTextStyles.bodyNormal.copyWith(
                              height: 1.45,
                              fontSize: 15,
                              color: AppColors.textPrimary.withValues(alpha: 0.92),
                            ),
                          ),
                        if (nextStepCard == null && headline.isNotEmpty)
                          const SizedBox(height: 24),
                        Text(
                          'VERIFICACIÓN',
                          style: AppTextStyles.bodyNormal.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._docRows().map(_buildDocTile),
                        const SizedBox(height: 28),
                        Text(
                          'PERFIL PROFESIONAL',
                          style: AppTextStyles.bodyNormal.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Accesos rápidos',
                          style: AppTextStyles.bodyNormal.copyWith(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        _buildQuickProfileActions(),
                        const SizedBox(height: 16),
                        ..._profileTasks().map(_buildProfileTile),
                        const SizedBox(height: 28),
                        _buildPublicationListingCard(),
                        const SizedBox(height: 16),
                        _buildActivationCard(),
                        const SizedBox(height: 20),
                        ..._buildBottomActions(),
                      ],
                    ),
                  ),
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
      case 'document_missing_file':
        return 'Documentación obligatoria completa';
      case 'document_not_approved':
        return 'Documentos aprobados por el equipo';
      case 'document_rejected':
        return 'Corregir documentos rechazados';
      case 'document_pending_review':
        return 'Documentos en revisión';
      default:
        return code;
    }
  }

  Widget? _buildPublishableStatusCard() {
    final p = _profile;
    if (p == null) return null;
    final pub = p['publishable'] == true;
    final raw = p['publishBlockedReasons'];
    final reasons = raw is List ? raw.map((e) => e.toString()).toList() : <String>[];

    if (pub) {
      return AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.public_outlined, color: AppColors.success, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Listo para aparecer en búsquedas',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tu cuenta está aprobada, la documentación verificada y la visibilidad pública activa. Los alumnos pueden encontrarte y reservarte.',
                    style: AppTextStyles.bodyNormal.copyWith(fontSize: 13, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (reasons.isEmpty) return null;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Para aparecer en búsquedas públicas',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Falta uno o más requisitos. Completalos y esperá la aprobación de documentos:',
            style: AppTextStyles.bodyNormal.copyWith(fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 10),
          ...reasons.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: AppTextStyles.bodyNormal.copyWith(color: AppColors.primary)),
                  Expanded(
                    child: Text(
                      _publishReasonLabel(c),
                      style: AppTextStyles.bodyNormal.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  (int, int) _checklistCounts() {
    final docs = _docRows();
    final tasks = _profileTasks().where((t) => t.essential).toList();
    var done = tasks.where((t) => t.done).length;
    for (final row in docs) {
      if (row.status == _DocUiStatus.approved) done += 1;
    }
    return (done, docs.length + tasks.length);
  }

  String? _recommendedNextStepLabel() {
    final p = _profile;
    if (p == null) return null;

    final rejected =
        _docRows().where((r) => r.status == _DocUiStatus.actionRequired).toList();
    if (rejected.isNotEmpty) {
      return 'Corregí «${rejected.first.label}» y volvé a subir el archivo.';
    }
    if (!RoleRouter.hasUploadedAllDocs(p)) {
      return 'Subí los 5 documentos obligatorios para avanzar con la verificación.';
    }
    if (!RoleRouter.isInstructorProfileBasicsComplete(p)) {
      return 'Completá tu perfil profesional: zona, bio, tarifa y foto.';
    }
    final mpConnected = _mpStatus?['connected'] == true;
    if (!mpConnected) {
      return 'Conectá Mercado Pago para poder recibir pagos de tus alumnos.';
    }
    if (p['publishable'] != true) {
      return 'Activá la visibilidad pública cuando la documentación esté aprobada.';
    }
    return null;
  }

  Widget? _buildNextStepCard() {
    final label = _recommendedNextStepLabel();
    if (label == null) return null;
    return ContextHelpCard(
      title: 'Próximo paso recomendado',
      body: label,
      icon: Icons.flag_circle_outlined,
    );
  }

  Widget _buildProgressHeader() {
    final total = _combinedProgress().clamp(0.0, 1.0);
    final v = _verificationFraction().clamp(0.0, 1.0);
    final pr = _profileFraction().clamp(0.0, 1.0);
    final (checkDone, checkTotal) = _checklistCounts();
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu perfil está $checkDone/$checkTotal listo',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'La verificación documental y el perfil suman por igual. Un documento en revisión cuenta parcialmente hasta que se apruebe.',
            style: AppTextStyles.bodyNormal.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total,
              minHeight: 8,
              backgroundColor: AppColors.surfaceLighter,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(total * 100).round()}% en total · Documentos ${(v * 100).round()}% · Perfil ${(pr * 100).round()}%',
            style: AppTextStyles.bodyNormal.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            'Por ahora, revisá Mis clases con frecuencia para ver nuevas reservas.',
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
          onTap: row.status == _DocUiStatus.missing || row.status == _DocUiStatus.actionRequired
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
                        style: AppTextStyles.bodyNormal.copyWith(fontSize: 12, height: 1.3),
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
                if (row.status == _DocUiStatus.missing || row.status == _DocUiStatus.actionRequired)
                  Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickProfileActions() {
    final p = _profile;
    if (p == null) return const SizedBox.shrink();
    final pub = RoleRouter.isInstructorPublishableFromApi(p);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          label: const Text('Experiencia'),
          onPressed: () => _openProfessionalProfileSection('experience_years'),
        ),
        ActionChip(
          label: const Text('Bio'),
          onPressed: () => _openProfessionalProfileSection('bio'),
        ),
        ActionChip(
          label: const Text('Tarifa'),
          onPressed: () => _openProfessionalProfileSection('hourly_rate'),
        ),
        ActionChip(
          label: const Text('Foto'),
          onPressed: () => _openProfessionalProfileSection('profile_photo'),
        ),
        ActionChip(
          label: const Text('Zona en mapa'),
          onPressed: () => _openProfessionalProfileSection('service_zone'),
        ),
        ActionChip(
          label: const Text('Visibilidad'),
          onPressed: () {
            if (pub) {
              _openProfessionalProfileSection('visibility');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'La visibilidad se habilita cuando la documentación esté aprobada y tu perfil sea publicable.',
                  ),
                ),
              );
            }
          },
        ),
      ],
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
    final reasonList = reasons is List ? reasons.map((e) => e.toString()).toList() : <String>[];

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publicación y visibilidad',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            listed
                ? 'Tu perfil está visible para alumnos (listado activo).'
                : canEnable
                    ? 'Ya podés activar la visibilidad en búsquedas. Abrí “Visibilidad” arriba o completá el interruptor en perfil profesional.'
                    : 'El listado público sigue bloqueado hasta cumplir documentación, perfil y cuenta. No bloquea que edites tu perfil.',
            style: AppTextStyles.bodyNormal.copyWith(fontSize: 13, height: 1.35),
          ),
          if (!listed && reasonList.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Motivos que impiden publicar aún:',
              style: AppTextStyles.bodyNormal.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            ...reasonList.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${_publishReasonLabel(c)}', style: AppTextStyles.bodyNormal.copyWith(fontSize: 12)),
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
                  t.done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
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
                      color: t.done ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
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
    final hasRejected = _docRows().any((r) => r.status == _DocUiStatus.actionRequired);
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
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(body, style: AppTextStyles.bodyNormal.copyWith(height: 1.4, fontSize: 14)),
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
