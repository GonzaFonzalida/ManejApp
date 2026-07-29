import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/config/premium_booking_ui.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import 'package:manejapp/models/premium_reservation.dart';
import 'package:manejapp/screens/student_reservation_detail_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_resume_refresh_mixin.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_empty_state.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/next_action_card.dart';
import 'package:manejapp/screens/home_screen.dart';
import '../widgets/skeleton_loader.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen>
    with WidgetsBindingObserver, AppResumeRefreshMixin {
  List<PremiumReservation> _upcoming = [];
  List<PremiumReservation> _history = [];
  bool _isLoading = true;
  String? _loadError;
  int _tabIndex = 0; // 0: próximas, 1: historial

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  bool _reservationNeedsPayment(PremiumReservation r) {
    if (r.status == 'PENDING_PAYMENT') return true;
    final p = r.paymentStatus.toLowerCase().trim();
    return p == 'pending' || p == 'in_process' || p == 'unpaid';
  }

  Widget _buildUpcomingNextAction(BuildContext context) {
    if (_upcoming.isEmpty) return const SizedBox.shrink();

    PremiumReservation? paymentOne;
    for (final r in _upcoming) {
      if (_reservationNeedsPayment(r)) {
        paymentOne = r;
        break;
      }
    }
    if (paymentOne != null) {
      final pay = paymentOne;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: NextActionCard(
          priority: NextActionPriority.urgent,
          icon: Icons.payments_rounded,
          statusLabel: 'Pago',
          title: 'Falta completar el pago',
          description:
              'Con ${pay.instructorName} quedó pendiente. Finalizalo para confirmar la clase.',
          primaryLabel: 'Ir al detalle',
          onPrimary: () async {
            await Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => StudentReservationDetailScreen(
                  reservationId: pay.id,
                ),
              ),
            );
            if (mounted) await _loadReservations();
          },
        ),
      );
    }

    final sorted = [..._upcoming]..sort((a, b) {
        final ta = a.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.startsAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });
    final next = sorted.first;
    final starts = next.startsAt;
    final when = starts == null
        ? 'Fecha por confirmar'
        : DateFormat("EEE d MMM 'a las' HH:mm", 'es').format(starts.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: NextActionCard(
        priority: NextActionPriority.calm,
        icon: Icons.event_rounded,
        title: 'Tu próxima clase',
        description: '${next.instructorName} · $when',
        primaryLabel: 'Ver reserva',
        onPrimary: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => StudentReservationDetailScreen(
                reservationId: next.id,
              ),
            ),
          );
          if (mounted) await _loadReservations();
        },
      ),
    );
  }

  @override
  void refreshOnAppResume() {
    _loadReservations(showLoading: false);
  }

  Future<void> _loadReservations({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final upcomingRaw =
          await ApiService.getStudentUpcomingReservationsPremium();
      final historyRaw =
          await ApiService.getStudentHistoryReservationsPremium();
      if (!mounted) return;
      setState(() {
        _upcoming = upcomingRaw
            .map((e) => PremiumReservation(Map<String, dynamic>.from(e as Map)))
            .toList();
        _history = historyRaw
            .map((e) => PremiumReservation(Map<String, dynamic>.from(e as Map)))
            .toList();
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _tabIndex == 0 ? _upcoming : _history;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mis reservas',
            style: AppTextStyles.heading.copyWith(fontSize: 24)),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: Navigator.of(context).canPop(),
        actions: [
          IconButton(
            key: E2eKeys.studentReservationsRefresh,
            tooltip: 'Actualizar reservas',
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: ListSkeletonLoader(itemCount: 4),
            )
          : _loadError != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AppErrorState(
                      title: 'No pudimos cargar tus reservas',
                      message: _loadError,
                      onRetry: _loadReservations,
                      retryLabel: 'Reintentar',
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: _SegmentedTabs(
                        index: _tabIndex,
                        onChanged: (i) => setState(() => _tabIndex = i),
                      ),
                    ),
                    if (_tabIndex == 0) _buildUpcomingNextAction(context),
                    Expanded(
                      child: activeList.isEmpty
                          ? _EmptyState(
                              key: E2eKeys.studentReservationsEmpty,
                              isUpcoming: _tabIndex == 0,
                            )
                          : RefreshIndicator(
                              onRefresh: _loadReservations,
                              color: AppColors.primary,
                              backgroundColor: AppColors.surfaceLight,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 24),
                                itemCount: activeList.length,
                                itemBuilder: (context, index) {
                                  final reservation = activeList[index];
                                  return _ReservationCard(
                                    reservation: reservation,
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              StudentReservationDetailScreen(
                                            reservationId: reservation.id,
                                          ),
                                        ),
                                      );
                                      if (mounted) {
                                        await _loadReservations();
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabButton(context,
              label: 'Próximas',
              isActive: index == 0,
              onTap: () => onChanged(0)),
          _tabButton(context,
              label: 'Historial',
              isActive: index == 1,
              onTap: () => onChanged(1)),
        ],
      ),
    );
  }

  Widget _tabButton(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: 'Pestaña $label',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppDurations.fast),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color:
                    isActive ? AppColors.textInverse : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final PremiumReservation reservation;
  final VoidCallback onTap;

  const _ReservationCard({
    required this.reservation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startsAt = reservation.startsAt;
    final status = _statusUi(reservation.status);
    final payColor = PremiumBookingUi.paymentAccent(reservation.paymentStatus);
    final payLabel =
        PremiumBookingUi.paymentShortLabel(reservation.paymentStatus);

    return Semantics(
      button: true,
      label: 'Abrir detalle de la reserva con ${reservation.instructorName}',
      child: GestureDetector(
        key: E2eKeys.studentReservationCard(reservation.id),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: status.color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLighter,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  startsAt == null
                                      ? 'Sin horario'
                                      : DateFormat('EEE d MMM · HH:mm', 'es')
                                          .format(startsAt),
                                  style: AppTextStyles.bodyNormal.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusPill(status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _paymentPill(payLabel, payColor),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.instructorName,
                      style: AppTextStyles.heading.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reservation.locationLabel,
                      style: AppTextStyles.bodyNormal,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${reservation.durationMinutes} min',
                          style: AppTextStyles.bodyNormal,
                        ),
                        Text(
                          reservation.priceLabel,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLighter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reservation.nextActionHintStudent,
                              style: AppTextStyles.bodyNormal.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusUi _statusUi(String status) {
    return _StatusUi(
      PremiumBookingUi.statusChipLabel(status),
      PremiumBookingUi.statusColor(status),
    );
  }

  Widget _paymentPill(String label, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_outlined, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodyNormal.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(_StatusUi status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.bodyNormal.copyWith(
          color: status.color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusUi {
  final String label;
  final Color color;
  const _StatusUi(this.label, this.color);
}

class _EmptyState extends StatelessWidget {
  final bool isUpcoming;

  const _EmptyState({super.key, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    if (isUpcoming) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: NextActionCard(
            priority: NextActionPriority.standard,
            icon: Icons.explore_outlined,
            title: 'Todavía no tenés reservas',
            description:
                'Cuando reserves una clase, vas a poder seguir acá si está pendiente, confirmada o cancelada.',
            primaryLabel: 'Buscar instructor',
            onPrimary: () {
              Navigator.pushNamed(context, HomeScreen.routeName);
            },
          ),
        ),
      );
    }

    return Center(
      child: AppEmptyState(
        icon: Icons.history_rounded,
        title: 'Todavía no hay historial',
        subtitle:
            'Cuando completes o canceles clases, vas a ver el registro acá, con fecha e instructor.',
      ),
    );
  }
}
