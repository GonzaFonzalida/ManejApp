import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/config/premium_booking_ui.dart';
import 'package:manejapp/models/premium_reservation.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/next_action_card.dart';
import 'package:manejapp/utils/app_resume_refresh_mixin.dart';
import 'package:manejapp/utils/role_router.dart';
import 'package:manejapp/screens/instructor_onboarding_hub_screen.dart';
import 'package:manejapp/screens/complete_instructor_profile_screen.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import '../models/schedule_slot.dart';
import 'instructor_schedule_screen.dart';
import 'instructor_classes_screen.dart';
import 'instructor_reservation_detail_screen.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/app_bottom_nav.dart';
import 'package:manejapp/widgets/skeleton_loader.dart';
import 'profile_screen.dart';

const storage = appSecureStorage;

class InstructorDashboardScreen extends StatefulWidget {
  static const routeName = '/instructor_dashboard';
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() =>
      _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen>
    with WidgetsBindingObserver, AppResumeRefreshMixin {
  int _selectedIndex = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args.containsKey('initialIndex')) {
        setState(() {
          _selectedIndex = args['initialIndex'] as int;
        });
      }
      _initialized = true;
    }
  }

  List<PremiumReservation> _todayPremium = [];
  List<PremiumReservation> _upcomingPremium = [];
  List<ScheduleSlot> _availableSlots = [];
  bool _hasAnyScheduleSlots = false;
  Map<String, dynamic>? _instructorMe;
  bool _isLoading = true;
  String _instructorName = '';
  String? _dashboardLoadError;

  @override
  void initState() {
    super.initState();
    _loadDashboardData(showFullSkeleton: true);
  }

  @override
  void refreshOnAppResume() {
    if (_selectedIndex == 0) {
      _loadDashboardData(showFullSkeleton: false);
    }
  }

  Future<void> _loadDashboardData({bool showFullSkeleton = false}) async {
    if (showFullSkeleton) {
      setState(() {
        _isLoading = true;
        _dashboardLoadError = null;
      });
    } else {
      setState(() => _dashboardLoadError = null);
    }
    try {
      final userId = await storage.read(key: 'user_id');
      if (userId == null) {
        if (mounted) {
          setState(() {
            _dashboardLoadError =
                'No hay sesión de instructor. Volvé a iniciar sesión.';
            _todayPremium = [];
            _upcomingPremium = [];
            _availableSlots = [];
            _hasAnyScheduleSlots = false;
            _instructorMe = null;
          });
        }
        return;
      }

      final instructor = await ApiService.getInstructorMeOrNull();

      if (instructor == null) {
        if (mounted) {
          setState(() {
            _dashboardLoadError =
                'No encontramos tu perfil de instructor. Completá el registro o contactá soporte.';
            _todayPremium = [];
            _upcomingPremium = [];
            _availableSlots = [];
            _hasAnyScheduleSlots = false;
            _instructorMe = null;
          });
        }
        return;
      }

      final instructorId = instructor['id'].toString();

      // Clases de hoy: mismo endpoint premium que «Mis clases».
      final upcomingRaw =
          await ApiService.getInstructorUpcomingReservationsPremium();
      final allUpcoming = upcomingRaw
          .map((e) => PremiumReservation(Map<String, dynamic>.from(e as Map)))
          .toList();
      allUpcoming.sort(
        (a, b) {
          final ka = PremiumBookingUi.instructorUpcomingSortKey(
            status: a.status,
            paymentStatus: a.paymentStatus,
          );
          final kb = PremiumBookingUi.instructorUpcomingSortKey(
            status: b.status,
            paymentStatus: b.paymentStatus,
          );
          if (ka != kb) return ka.compareTo(kb);
          return (a.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        },
      );
      _upcomingPremium = allUpcoming;
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      _todayPremium = allUpcoming.where((r) {
        final s = r.startsAt;
        if (s == null) return false;
        final local = s.toLocal();
        final d = DateTime(local.year, local.month, local.day);
        return d == todayOnly;
      }).toList();
      _todayPremium.sort(
        (a, b) => (a.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(b.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );

      final slots = await ApiService.getInstructorSchedule(instructorId);
      _hasAnyScheduleSlots = slots.isNotEmpty;
      _availableSlots = slots
          .where((s) => s['isBooked'] != true)
          .map((s) => ScheduleSlot.fromJson(s))
          .toList();

      _instructorMe = await ApiService.getInstructorMeOrNull();

      _instructorName =
          '${instructor['user']?['firstName'] ?? ''} ${instructor['user']?['lastName'] ?? ''}'
              .trim();
      if (_instructorName.isEmpty) _instructorName = 'Instructor';
    } catch (e) {
      debugPrint('ERROR cargando dashboard: $e');
      if (mounted) {
        setState(() {
          _dashboardLoadError =
              'No pudimos cargar el panel. Revisá tu conexión e intentá de nuevo.';
          _todayPremium = [];
          _upcomingPremium = [];
          _availableSlots = [];
          _hasAnyScheduleSlots = false;
          _instructorMe = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Inicio', style: AppTextStyles.heading),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              key: E2eKeys.instructorDashboardRefresh,
              tooltip: 'Actualizar panel',
              onPressed: _isLoading ? null : () => _loadDashboardData(),
              icon: Icon(
                Icons.refresh,
                color: _isLoading ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              child: Text(
                _instructorName.isNotEmpty
                    ? _instructorName[0].toUpperCase()
                    : 'I',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          )
        ],
      ),
      body: _isLoading ? _buildDashboardSkeleton() : _buildBody(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <AppBottomNavItem>[
          AppBottomNavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard_rounded,
            label: 'Inicio',
          ),
          AppBottomNavItem(
            icon: Icons.schedule_outlined,
            selectedIcon: Icons.schedule_rounded,
            label: 'Horarios',
          ),
          AppBottomNavItem(
            icon: Icons.school_outlined,
            selectedIcon: Icons.school_rounded,
            label: 'Clases',
          ),
          AppBottomNavItem(
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const InstructorScheduleScreen();
      case 2:
        return const InstructorClassesScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final nextAction = _buildInstructorNextAction();
    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            Text(
              'Hola, $_instructorName',
              style: AppTextStyles.heading.copyWith(fontSize: 26, height: 1.15),
            ),
            const SizedBox(height: 8),
            Text(
              'Resumen de lo que importa hoy',
              style: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            if (nextAction != null) ...[
              nextAction,
              const SizedBox(height: 24),
            ],
            if (_buildAttentionBanner() case final banner?) ...[
              banner,
              const SizedBox(height: 24),
            ],

            // Resumen Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Clases hoy',
                    _todayPremium.length.toString(),
                    Icons.school_outlined,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Turnos libres',
                    _availableSlots.length.toString(),
                    Icons.event_available_outlined,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Agenda de hoy',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _todayPremium.isEmpty
                  ? 'Cuando tengas reservas para hoy, las vas a ver acá al instante.'
                  : 'Tocá una fila para abrir el detalle premium de la reserva.',
              style: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            if (_dashboardLoadError != null) ...[
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: AppErrorState(
                  title: 'No pudimos actualizar el panel',
                  message: _dashboardLoadError,
                  onRetry: () => _loadDashboardData(showFullSkeleton: true),
                  retryLabel: 'Reintentar',
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_todayPremium.isEmpty)
              KeyedSubtree(
                key: E2eKeys.instructorTodayEmpty,
                child: _buildTodayEmptySection(),
              )
            else
              ..._todayPremium.take(3).map(_buildTodayPremiumCard),

            const SizedBox(height: 24),

            Text(
              'Accesos rápidos',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InstructorQuickTile(
                    icon: Icons.schedule_rounded,
                    label: 'Horarios',
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InstructorQuickTile(
                    icon: Icons.school_rounded,
                    label: 'Clases',
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InstructorQuickTile(
                    icon: Icons.directions_car_rounded,
                    label: 'Vehículo',
                    onTap: () =>
                        Navigator.pushNamed(context, '/instructor_car'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Una sola acción prioritaria (documentos, perfil, agenda vacía o próxima clase hoy).
  Widget? _buildInstructorNextAction() {
    if (_dashboardLoadError != null) return null;

    final me = _instructorMe;
    if (me != null) {
      if (RoleRouter.hasRejectedDocument(me)) {
        return NextActionCard(
          priority: NextActionPriority.urgent,
          icon: Icons.gpp_bad_outlined,
          statusLabel: 'Revisar',
          title: 'Un documento necesita corrección',
          description:
              'Subí la versión ajustada así no se frena tu actividad mientras lo revisamos.',
          primaryLabel: 'Ver documentos',
          onPrimary: () {
            Navigator.pushNamed(
                context, InstructorOnboardingHubScreen.routeName);
          },
        );
      }
      if (!RoleRouter.hasUploadedAllDocs(me) || me['isValid'] != true) {
        return NextActionCard(
          priority: NextActionPriority.high,
          icon: Icons.folder_special_outlined,
          statusLabel: 'Pendiente',
          title: 'Falta cerrar la documentación',
          description:
              'Completá los archivos obligatorios o esperá la validación para empezar tranquilo.',
          primaryLabel: 'Ir al centro de alta',
          onPrimary: () {
            Navigator.pushNamed(
                context, InstructorOnboardingHubScreen.routeName);
          },
        );
      }
      if (!RoleRouter.isInstructorProfileComplete(me)) {
        return NextActionCard(
          priority: NextActionPriority.high,
          icon: Icons.badge_outlined,
          statusLabel: 'Perfil',
          title: 'Tu perfil público está incompleto',
          description:
              'Tarifa, zona, bio y foto ayudan a que te elijan con confianza.',
          primaryLabel: 'Completar perfil',
          onPrimary: () {
            Navigator.pushNamed(
                context, CompleteInstructorProfileScreen.routeName);
          },
        );
      }
    }

    if (!_hasAnyScheduleSlots) {
      return NextActionCard(
        priority: NextActionPriority.standard,
        icon: Icons.schedule_outlined,
        title: 'Todavía no publicaste horarios',
        description:
            'Sin bloques disponibles los alumnos no pueden reservarte. Empezá con uno o dos turnos.',
        primaryLabel: 'Cargar horarios',
        onPrimary: () => setState(() => _selectedIndex = 1),
      );
    }

    // Con clases hoy, la lista de agenda ya concentra el foco; evitamos duplicar otro NextAction.
    return null;
  }

  /// Banner contextual cuando hay reservas que requieren atención o próxima clase relevante.
  Widget? _buildAttentionBanner() {
    if (_upcomingPremium.isEmpty) return null;

    final manualReview = _upcomingPremium
        .where((r) => PremiumBookingUi.isManualReviewPayment(r.paymentStatus))
        .toList();
    final pendingPayment = _upcomingPremium
        .where(
          (r) =>
              !PremiumBookingUi.isManualReviewPayment(r.paymentStatus) &&
              PremiumBookingUi.instructorReservationNeedsAttention(
                status: r.status,
                paymentStatus: r.paymentStatus,
              ),
        )
        .toList();

    final now = DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    String? title;
    String? description;
    NextActionPriority priority = NextActionPriority.standard;
    IconData icon = Icons.event_note_outlined;

    if (manualReview.isNotEmpty) {
      priority = NextActionPriority.high;
      icon = Icons.support_agent_outlined;
      title = manualReview.length == 1
          ? 'Hay una reserva con pago en revisión'
          : 'Hay ${manualReview.length} reservas con pago en revisión';
      description =
          'No requiere acción por ahora. Revisá el estado en Mis clases.';
    } else if (pendingPayment.isNotEmpty) {
      priority = NextActionPriority.urgent;
      icon = Icons.payments_outlined;
      title = pendingPayment.length == 1
          ? 'Tenés una reserva esperando pago'
          : 'Tenés ${pendingPayment.length} reservas esperando pago';
      description = 'El alumno debe completar el pago para confirmar la clase.';
    } else {
      PremiumReservation? nextConfirmed;
      for (final r in _upcomingPremium) {
        if (r.status == 'CONFIRMED') {
          nextConfirmed = r;
          break;
        }
      }
      final startsAt = nextConfirmed?.startsAt?.toLocal();
      if (startsAt == null) return null;
      final day = DateTime(startsAt.year, startsAt.month, startsAt.day);
      if (day == todayOnly) return null;

      priority = NextActionPriority.calm;
      icon = Icons.calendar_today_outlined;
      var dateLine = DateFormat('EEEE d MMMM · HH:mm', 'es').format(startsAt);
      dateLine = toBeginningOfSentenceCase(dateLine) ?? dateLine;
      title = 'Tu próxima reserva es el $dateLine';
      description = 'Revisá alumno, hora y ubicación en Mis clases.';
    }

    return NextActionCard(
      priority: priority,
      icon: icon,
      title: title,
      description: description,
      primaryLabel: 'Ver mis clases',
      onPrimary: () => setState(() => _selectedIndex = 2),
    );
  }

  Widget _buildTodayEmptySection() {
    if (!_hasAnyScheduleSlots) {
      return AppCard(
        variant: AppCardVariant.outlined,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 40,
              color: AppColors.textSecondary.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 12),
            Text(
              'Tu agenda empieza publicando horarios',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Sin horarios publicados, los alumnos no pueden reservarte. Cargá tus horarios disponibles para empezar.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyNormal.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 40,
            color: AppColors.textSecondary.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 12),
          Text(
            'Hoy no tenés clases agendadas',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando un alumno reserve, vas a verlo en Mis clases. Revisá la app con frecuencia para enterarte de nuevas reservas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyNormal.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTextStyles.displayLarge.copyWith(fontSize: 28),
          ),
          Text(
            title,
            style: AppTextStyles.bodyNormal.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPremiumCard(PremiumReservation r) {
    final statusColor = PremiumBookingUi.statusColor(r.status);
    final timeLine = r.startsAt == null
        ? 'Horario a confirmar'
        : '${DateFormat('HH:mm').format(r.startsAt!.toLocal())} · ${r.durationMinutes} min';
    final pay = PremiumBookingUi.paymentShortLabel(r.paymentStatus);

    return Semantics(
      button: true,
      label: 'Abrir clase de hoy con ${r.studentName}',
      child: GestureDetector(
        key: E2eKeys.instructorTodayCard(r.id),
        onTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => InstructorReservationDetailScreen(
                reservationId: r.id,
              ),
            ),
          );
          if (mounted) await _loadDashboardData();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.directions_car_filled_outlined,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.studentName,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeLine,
                        style: AppTextStyles.bodyNormal,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pay,
                        style: AppTextStyles.bodyNormal.copyWith(
                          color:
                              PremiumBookingUi.paymentAccent(r.paymentStatus),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    PremiumBookingUi.statusChipLabel(r.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(
              width: 200,
              height: 32,
              borderRadius: BorderRadius.all(Radius.circular(8))),
          const SizedBox(height: 8),
          const SkeletonLoader(
              width: 250,
              height: 20,
              borderRadius: BorderRadius.all(Radius.circular(4))),
          const SizedBox(height: 24),

          // Stats
          Row(children: [
            Expanded(
                child: SkeletonLoader(
                    width: double.infinity,
                    height: 120,
                    borderRadius: BorderRadius.all(Radius.circular(24)))),
            const SizedBox(width: 16),
            Expanded(
                child: SkeletonLoader(
                    width: double.infinity,
                    height: 120,
                    borderRadius: BorderRadius.all(Radius.circular(24)))),
          ]),
          const SizedBox(height: 24),

          // Upcoming
          const SkeletonLoader(
              width: 150,
              height: 24,
              borderRadius: BorderRadius.all(Radius.circular(8))),
          const SizedBox(height: 16),
          const SkeletonLoader(
              width: double.infinity,
              height: 80,
              borderRadius: BorderRadius.all(Radius.circular(16))),
          const SizedBox(height: 16),
          const SkeletonLoader(
              width: double.infinity,
              height: 80,
              borderRadius: BorderRadius.all(Radius.circular(16))),
        ],
      ),
    );
  }
}

class _InstructorQuickTile extends StatelessWidget {
  const _InstructorQuickTile({
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
