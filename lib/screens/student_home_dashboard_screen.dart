import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/config/premium_booking_ui.dart';
import 'package:manejapp/models/premium_reservation.dart';
import 'package:manejapp/navigation/explore_intent.dart';
import 'package:manejapp/screens/editar_perfil_screen.dart';
import 'package:manejapp/screens/home_screen.dart';
import 'package:manejapp/screens/student_reservation_detail_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/utils/student_profile_completion.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/utils/app_resume_refresh_mixin.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/next_action_card.dart';
import 'package:manejapp/widgets/skeleton_loader.dart';
import 'package:manejapp/keys/e2e_keys.dart';

const _storage = appSecureStorage;

/// Centro de control del alumno: prioridad clara, un solo [NextActionCard] y accesos rápidos.
class StudentHomeDashboardScreen extends StatefulWidget {
  const StudentHomeDashboardScreen({
    super.key,
    required this.onSwitchTab,
  });

  /// Pestañas del shell: 0 inicio, 1 reservas, 2 perfil, 3 ajustes.
  final ValueChanged<int> onSwitchTab;

  @override
  State<StudentHomeDashboardScreen> createState() =>
      _StudentHomeDashboardScreenState();
}

class _StudentHomeDashboardScreenState extends State<StudentHomeDashboardScreen>
    with WidgetsBindingObserver, AppResumeRefreshMixin {
  bool _loading = true;
  String? _loadError;
  String _greetingName = '';
  List<PremiumReservation> _upcoming = [];
  int? _profilePercent;
  ProfilePrompt? _profilePrompt;

  final TextEditingController _homeSearchController = TextEditingController();
  bool _prefNearMe = true;
  bool _chipAutomatic = false;
  bool _chipManual = false;
  bool _chipToday = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void refreshOnAppResume() {
    unawaited(_load(showLoading: false));
  }

  @override
  void dispose() {
    _homeSearchController.dispose();
    super.dispose();
  }

  ExploreIntent _intentForExplore({bool focusZone = false}) {
    String? tx;
    if (_chipAutomatic) tx = 'AUTOMATIC';
    if (_chipManual) tx = 'MANUAL';
    return ExploreIntent(
      preferUserAnchor: _prefNearMe,
      transmission: tx,
      availableToday: _chipToday,
      initialInstructorNameQuery: _homeSearchController.text.trim().isEmpty
          ? null
          : _homeSearchController.text.trim(),
      focusZoneSearch: focusZone,
    );
  }

  void _openExplore({bool focusZone = false}) {
    Navigator.pushNamed(
      context,
      HomeScreen.routeName,
      arguments: _intentForExplore(focusZone: focusZone),
    );
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        if (mounted) {
          setState(() {
            _loading = false;
            _loadError = 'No encontramos tu sesión. Volvé a iniciar sesión.';
          });
        }
        return;
      }

      final profile = await ApiService.getUserProfile(userId);
      final name = profile['name']?.toString().trim() ?? '';
      final first = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
      final pct = StudentProfileCompletion.completionPercent(profile);
      final prompts = StudentProfileCompletion.promptsFor(profile);
      final prompt = pct < 100 && prompts.isNotEmpty ? prompts.first : null;

      final upcomingRaw =
          await ApiService.getStudentUpcomingReservationsPremium();
      final list = upcomingRaw
          .map((e) => PremiumReservation(Map<String, dynamic>.from(e as Map)))
          .toList();
      list.sort((a, b) {
        final ta = a.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });

      if (mounted) {
        setState(() {
          _greetingName = first;
          _profilePercent = pct;
          _profilePrompt = prompt;
          _upcoming = list;
          _loading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = humanizeApiError(e);
        });
      }
    }
  }

  bool _needsPayment(PremiumReservation r) {
    if (r.status == 'PENDING_PAYMENT') return true;
    final p = r.paymentStatus.toLowerCase().trim();
    return p == 'pending' || p == 'in_process' || p == 'unpaid';
  }

  PremiumReservation? get _firstPaymentPending {
    for (final r in _upcoming) {
      if (_needsPayment(r)) return r;
    }
    return null;
  }

  PremiumReservation? get _nextClass {
    for (final r in _upcoming) {
      if (!_needsPayment(r)) return r;
    }
    return null;
  }

  /// Prioridad: pago → perfil → próxima clase (destacada) → sin clases.
  Widget _buildFocusCard(BuildContext context) {
    final pay = _firstPaymentPending;
    if (pay != null) {
      final more = _upcoming.where(_needsPayment).length > 1;
      return NextActionCard(
        priority: NextActionPriority.urgent,
        icon: Icons.payments_rounded,
        statusLabel: 'Pago',
        title: 'Tenés un pago pendiente',
        description: more
            ? 'Hay más de una reserva esperando pago. Empezá por esta con ${pay.instructorName}.'
            : 'Con ${pay.instructorName} falta cerrar el pago para confirmar la clase.',
        primaryLabel: 'Completar ahora',
        onPrimary: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  StudentReservationDetailScreen(reservationId: pay.id),
            ),
          );
          if (mounted) await _load();
        },
        secondaryLabel: 'Ver todas',
        onSecondary: () => widget.onSwitchTab(1),
      );
    }

    final prompt = _profilePrompt;
    final pct = _profilePercent;
    if (prompt != null && pct != null) {
      return NextActionCard(
        priority:
            pct < 50 ? NextActionPriority.high : NextActionPriority.standard,
        icon: Icons.person_outline_rounded,
        statusLabel: '$pct%',
        title: prompt.title,
        description: prompt.subtitle,
        primaryLabel: prompt.actionLabel,
        onPrimary: () {
          Navigator.pushNamed(context, EditarPerfilScreen.routeName).then((_) {
            if (mounted) unawaited(_load());
          });
        },
      );
    }

    final next = _nextClass;
    if (next != null) {
      final starts = next.startsAt;
      final when = starts == null
          ? 'Fecha por confirmar'
          : DateFormat("EEE d MMM · HH:mm", 'es').format(starts.toLocal());
      return _NextClassHighlight(
        instructorName: next.instructorName,
        whenLine: when,
        paymentStatus: next.paymentStatus,
        paymentLabel: PremiumBookingUi.paymentShortLabel(next.paymentStatus),
        statusLabel: PremiumBookingUi.statusChipLabel(next.status),
        statusColor: PremiumBookingUi.statusColor(next.status),
        onOpen: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  StudentReservationDetailScreen(reservationId: next.id),
            ),
          );
          if (mounted) await _load();
        },
      );
    }

    return NextActionCard(
      key: E2eKeys.studentHomeNoBookingsCard,
      priority: NextActionPriority.standard,
      icon: Icons.explore_outlined,
      title: 'Todavía no reservaste',
      description:
          'Explorá instructores en el mapa, compará y elegí tu primer horario.',
      primaryLabel: 'Explorar instructores',
      onPrimary: () => _openExplore(),
    );
  }

  Widget _buildHomeSearchTool(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _homeSearchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _openExplore(),
            style:
                AppTextStyles.bodyNormal.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '¿Dónde o con quién querés aprender a manejar?',
              hintStyle: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.surfaceLighter,
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.near_me_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _prefNearMe
                      ? 'Priorizamos instructores cerca de tu ubicación.'
                      : 'Vas a elegir zona en el mapa al explorar.',
                  style: AppTextStyles.bodyNormal.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openExplore(focusZone: true),
                child: const Text('Cambiar'),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _homeFilterChip(
                  label: 'Cerca mío',
                  selected: _prefNearMe,
                  onTap: () => setState(() => _prefNearMe = !_prefNearMe),
                ),
                SizedBox(width: AppSpacing.xs),
                _homeFilterChip(
                  label: 'Automático',
                  selected: _chipAutomatic,
                  onTap: () => setState(() {
                    if (_chipAutomatic) {
                      _chipAutomatic = false;
                    } else {
                      _chipAutomatic = true;
                      _chipManual = false;
                    }
                  }),
                ),
                SizedBox(width: AppSpacing.xs),
                _homeFilterChip(
                  label: 'Manual',
                  selected: _chipManual,
                  onTap: () => setState(() {
                    if (_chipManual) {
                      _chipManual = false;
                    } else {
                      _chipManual = true;
                      _chipAutomatic = false;
                    }
                  }),
                ),
                SizedBox(width: AppSpacing.xs),
                _homeFilterChip(
                  label: 'Disponible hoy',
                  selected: _chipToday,
                  onTap: () => setState(() => _chipToday = !_chipToday),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Explorar instructores',
            icon: Icons.map_rounded,
            onPressed: () => _openExplore(),
          ),
        ],
      ),
    );
  }

  Widget _homeFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Filtro $label',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppMotion.duration(context, AppDurations.fast),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceLighter,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.textInverse : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accesos rápidos',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.search_rounded,
                label: 'Explorar',
                onTap: () => _openExplore(),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.event_note_rounded,
                label: 'Mis reservas',
                onTap: () => widget.onSwitchTab(1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var dateLine = DateFormat('EEEE d MMMM', 'es').format(now);
    dateLine = toBeginningOfSentenceCase(dateLine) ?? dateLine;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _loading
              ? KeyedSubtree(
                  key: const ValueKey<String>('dash_loading'),
                  child: _buildSkeleton(),
                )
              : _loadError != null
                  ? KeyedSubtree(
                      key: const ValueKey<String>('dash_error'),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: AppErrorState(
                                title: 'No pudimos cargar tu inicio',
                                message: _loadError,
                                onRetry: _load,
                                retryLabel: 'Reintentar',
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey<String>('dash_ok'),
                      child: RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceLight,
                        onRefresh: _load,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.panel,
                                AppSpacing.lg,
                                AppSpacing.panel,
                                AppSpacing.xxl,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  Text(
                                    _greetingName.isEmpty
                                        ? 'Hola'
                                        : 'Hola, $_greetingName',
                                    style: AppTextStyles.heading.copyWith(
                                      fontSize: 22,
                                      height: 1.12,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    dateLine,
                                    style: AppTextStyles.bodyNormal.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.md),
                                  _buildHomeSearchTool(context),
                                  SizedBox(height: AppSpacing.lg),
                                  _buildQuickActions(context),
                                  SizedBox(height: AppSpacing.lg),
                                  Text(
                                    'Seguimiento',
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.sm),
                                  _buildFocusCard(context),
                                  if (_profilePercent != null &&
                                      _profilePercent! < 100 &&
                                      _profilePrompt == null) ...[
                                    SizedBox(height: AppSpacing.md),
                                    _ProfileProgressStrip(
                                        percent: _profilePercent!),
                                  ],
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.panel),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(
            width: 220,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(height: 10),
          const SkeletonLoader(
            width: 160,
            height: 16,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 24),
          SkeletonLoader(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          const SizedBox(height: 24),
          const SkeletonLoader(
            width: 140,
            height: 20,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 88,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 88,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: 88,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Próxima clase con jerarquía visual propia (no duplicar otro NextAction encima).
class _NextClassHighlight extends StatelessWidget {
  const _NextClassHighlight({
    required this.instructorName,
    required this.whenLine,
    required this.paymentStatus,
    required this.paymentLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.onOpen,
  });

  final String instructorName;
  final String whenLine;
  final String paymentStatus;
  final String paymentLabel;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Tu próxima clase',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            instructorName,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            whenLine,
            style: AppTextStyles.bodyNormal.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            paymentLabel,
            style: AppTextStyles.bodyNormal.copyWith(
              color: PremiumBookingUi.paymentAccent(paymentStatus),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Ver detalle',
            type: AppButtonType.primary,
            size: AppButtonSize.md,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.45),
              width: AppStroke.hairline,
            ),
            boxShadow: AppShadows.sm,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primary, size: 26),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileProgressStrip extends StatelessWidget {
  const _ProfileProgressStrip({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 18, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Perfil al $percent%',
                style: AppTextStyles.bodyNormal.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLighter,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
