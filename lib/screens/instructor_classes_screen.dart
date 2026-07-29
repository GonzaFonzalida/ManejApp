import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/config/premium_booking_ui.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import 'package:manejapp/models/premium_reservation.dart';
import 'package:manejapp/screens/instructor_dashboard_screen.dart';
import 'package:manejapp/screens/instructor_reservation_detail_screen.dart';
import 'package:manejapp/widgets/design/app_empty_state.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_resume_refresh_mixin.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/widgets/skeleton_loader.dart';

/// Listado premium de clases/reservas del instructor (Próximas / Historial).
/// Datos: `GET /classes/instructor/upcoming` y `history`.
class InstructorClassesScreen extends StatefulWidget {
  const InstructorClassesScreen({super.key});

  @override
  State<InstructorClassesScreen> createState() =>
      _InstructorClassesScreenState();
}

class _InstructorClassesScreenState extends State<InstructorClassesScreen>
    with WidgetsBindingObserver, AppResumeRefreshMixin {
  List<PremiumReservation> _upcoming = [];
  List<PremiumReservation> _history = [];
  bool _isLoading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  @override
  void refreshOnAppResume() {
    _loadReservations(showLoading: false);
  }

  void _sortUpcomingInPlace() {
    _upcoming.sort((a, b) {
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
    });
  }

  List<PremiumReservation> get _attentionUpcoming => _upcoming
      .where(
        (r) => PremiumBookingUi.instructorReservationNeedsAttention(
          status: r.status,
          paymentStatus: r.paymentStatus,
        ),
      )
      .toList();

  List<PremiumReservation> get _regularUpcoming => _upcoming
      .where(
        (r) => !PremiumBookingUi.instructorReservationNeedsAttention(
          status: r.status,
          paymentStatus: r.paymentStatus,
        ),
      )
      .toList();

  Future<void> _loadReservations({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final upcomingRaw =
          await ApiService.getInstructorUpcomingReservationsPremium();
      final historyRaw =
          await ApiService.getInstructorHistoryReservationsPremium();
      if (!mounted) return;
      setState(() {
        _upcoming = upcomingRaw
            .map((e) => PremiumReservation(Map<String, dynamic>.from(e as Map)))
            .toList();
        _history = historyRaw
            .map((e) => PremiumReservation(Map<String, dynamic>.from(e as Map)))
            .toList();
        _sortUpcomingInPlace();
      });
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        'No pudimos cargar tus clases. Revisá tu conexión e intentá nuevamente.',
      );
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
        title: Text(
          'Mis clases',
          style: AppTextStyles.heading.copyWith(fontSize: 24),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            key: E2eKeys.instructorClassesRefresh,
            tooltip: 'Actualizar clases',
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: _SegmentedTabs(
                    index: _tabIndex,
                    onChanged: (i) => setState(() => _tabIndex = i),
                    upcomingCount: _upcoming.length,
                    historyCount: _history.length,
                  ),
                ),
                Expanded(
                  child: activeList.isEmpty
                      ? _EmptyState(
                          key: E2eKeys.instructorClassesEmpty(
                            upcoming: _tabIndex == 0,
                          ),
                          isUpcoming: _tabIndex == 0,
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReservations,
                          color: AppColors.primary,
                          backgroundColor: AppColors.surfaceLight,
                          child: _tabIndex == 0
                              ? _buildUpcomingList()
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 12, 20, 24),
                                  itemCount: activeList.length,
                                  itemBuilder: (context, index) {
                                    final reservation = activeList[index];
                                    return _buildReservationCard(reservation);
                                  },
                                ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildUpcomingList() {
    final attention = _attentionUpcoming;
    final regular = _regularUpcoming;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (attention.isNotEmpty) ...[
          Text(
            'Requieren atención',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          for (final reservation in attention)
            _buildReservationCard(reservation),
          if (regular.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Próximas confirmadas',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
        for (final reservation in regular) _buildReservationCard(reservation),
      ],
    );
  }

  Widget _buildReservationCard(PremiumReservation reservation) {
    return _InstructorReservationCard(
      reservation: reservation,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InstructorReservationDetailScreen(
              reservationId: reservation.id,
            ),
          ),
        );
        if (mounted) await _loadReservations();
      },
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final int upcomingCount;
  final int historyCount;

  const _SegmentedTabs({
    required this.index,
    required this.onChanged,
    required this.upcomingCount,
    required this.historyCount,
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
          _tabButton(
            context,
            label: 'Próximas',
            subtitle: '$upcomingCount',
            isActive: index == 0,
            onTap: () => onChanged(0),
          ),
          _tabButton(
            context,
            label: 'Historial',
            subtitle: '$historyCount',
            isActive: index == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(
    BuildContext context, {
    required String label,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: 'Pestaña $label, $subtitle clases',
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppDurations.fast),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isActive
                        ? AppColors.textInverse
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyNormal.copyWith(
                    fontSize: 12,
                    color: isActive
                        ? AppColors.textInverse.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _InstructorReservationCard extends StatelessWidget {
  final PremiumReservation reservation;
  final VoidCallback onTap;

  const _InstructorReservationCard({
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
      label: 'Abrir detalle de la clase con ${reservation.studentName}',
      child: GestureDetector(
        key: E2eKeys.instructorReservationCard(reservation.id),
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
                      reservation.studentName,
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
                              reservation.nextActionHintInstructor,
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
        child: AppEmptyState(
          icon: Icons.event_available_outlined,
          title: 'Todavía no recibiste reservas',
          subtitle:
              'Cuando un alumno reserve un horario, vas a verlo acá. Revisá Mis clases con frecuencia.',
          actionLabel: 'Ver horarios publicados',
          onAction: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              InstructorDashboardScreen.routeName,
              (route) => false,
              arguments: {'initialIndex': 1},
            );
          },
        ),
      );
    }

    return Center(
      child: AppEmptyState(
        icon: Icons.history_rounded,
        title: 'Historial vacío',
        subtitle:
            'Cuando completes o canceles clases, vas a ver el registro acá.',
      ),
    );
  }
}
