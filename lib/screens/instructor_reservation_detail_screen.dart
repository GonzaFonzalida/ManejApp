import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/config/premium_booking_ui.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import 'package:manejapp/models/premium_reservation.dart';
import 'package:manejapp/screens/instructor_dashboard_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/cancellation_reason_copy.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/confirmation_dialog.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_availability_hint.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/premium_async_states.dart';
import 'package:manejapp/widgets/design/app_input.dart';
import 'package:manejapp/widgets/experience_level_slider.dart';
import 'package:manejapp/utils/whatsapp.dart';

class InstructorReservationDetailScreen extends StatefulWidget {
  final int reservationId;

  const InstructorReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  State<InstructorReservationDetailScreen> createState() =>
      _InstructorReservationDetailScreenState();
}

class _InstructorReservationDetailScreenState
    extends State<InstructorReservationDetailScreen> {
  PremiumReservation? _reservation;
  bool _loading = true;
  String? _loadError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final data = await ApiService.getInstructorReservationDetailPremium(
        widget.reservationId.toString(),
      );
      if (!mounted) return;
      setState(() {
        _reservation = PremiumReservation(data);
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _reservation = null;
        _loadError = humanizeApiError(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handlePrimaryAction() async {
    final reservation = _reservation;
    if (reservation == null) return;

    switch (reservation.nextRecommendedAction) {
      case 'OPEN_NEW_AVAILABILITY_SLOT':
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          InstructorDashboardScreen.routeName,
          (route) => false,
          arguments: {'initialIndex': 1},
        );
        return;
      default:
        await _loadDetail();
        if (mounted) {
          AppFeedback.showInfo(context, 'Estado actualizado.');
        }
    }
  }

  bool get _canMarkCompleted {
    final r = _reservation;
    if (r == null) return false;
    if (r.status != 'CONFIRMED') return false;
    final start = r.startsAt;
    if (start == null) return false;
    return !start.isAfter(DateTime.now());
  }

  Future<void> _completeClass() async {
    final reservation = _reservation;
    if (reservation == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _InstructorCompleteClassDialog(
        studentName: reservation.studentName,
      ),
    );

    if (result == null) return;

    setState(() => _submitting = true);
    try {
      await ApiService.updateDrivingClass(
        reservation.id.toString(),
        {
          'status': 'completed',
          'notes': result['notes'],
          'rating': result['rating'],
        },
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Clase registrada como completada.');
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancelReservation() async {
    final reservation = _reservation;
    if (reservation == null) return;

    if (!reservation.canCancel) {
      AppFeedback.showInfo(
        context,
        'Esta reserva ya no se puede cancelar según la política actual.',
      );
      return;
    }

    final deadlineLabel = reservation.cancelDeadline == null
        ? 'sin deadline informado'
        : DateFormat(
            'EEEE d MMM · HH:mm',
            'es',
          ).format(reservation.cancelDeadline!);

    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Cancelar clase',
      message:
          'Podés cancelar hasta $deadlineLabel.\n\n${reservation.policyText}\n\n¿Querés continuar?',
      confirmText: 'Sí, cancelar',
      cancelText: 'Volver',
      confirmButtonKey: E2eKeys.dialogConfirm,
    );

    if (confirm != true) return;

    setState(() => _submitting = true);
    try {
      await ApiService.cancelDrivingClass(reservation.id.toString());
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Clase cancelada correctamente.');
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final reservation = _reservation;
    if (reservation == null || !reservation.whatsappEnabled) return;
    final opened = await openWhatsAppLaunchUrl(reservation.whatsappLaunchUrl);
    if (!mounted) return;
    if (!opened) {
      AppFeedback.showError(
          context, 'No pudimos abrir WhatsApp en este dispositivo.');
    }
  }

  String? _experienceLine(int? level) {
    if (level == null) return null;
    final i = level.clamp(1, 5);
    final label = ExperienceLevelSlider.levelLabels[i - 1];
    return 'Nivel $i — $label';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const BookingDetailLoadingScaffold(title: 'Detalle de clase');
    }

    final reservation = _reservation;
    if (reservation == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AppErrorState(
              title: 'No pudimos abrir esta clase',
              message: _loadError,
              onRetry: _loadDetail,
              retryLabel: 'Reintentar',
              retryButtonKey: E2eKeys.instructorReservationDetailRetry,
            ),
          ),
        ),
      );
    }

    final startsAt = reservation.startsAt;
    final endsAt = reservation.endsAt;
    final statusColor = PremiumBookingUi.statusColor(reservation.status);
    final payAccent = PremiumBookingUi.paymentAccent(reservation.paymentStatus);
    final expLine = _experienceLine(reservation.studentExperienceLevel);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Detalle de clase',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reservation.studentName,
                                      style: AppTextStyles.heading.copyWith(
                                        fontSize: 20,
                                      ),
                                    ),
                                    if (expLine != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.psychology_outlined,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              expLine,
                                              style: AppTextStyles.bodyNormal
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  PremiumBookingUi.statusLabel(
                                      reservation.status),
                                  style: AppTextStyles.bodyNormal.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            reservation.locationLabel,
                            style: AppTextStyles.bodyNormal,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: payAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: payAccent.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                PremiumBookingUi.paymentShortLabel(
                                  reservation.paymentStatus,
                                ),
                                style: AppTextStyles.bodyNormal.copyWith(
                                  color: payAccent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          if (PremiumBookingUi.paymentDetailNote(
                            reservation.paymentStatus,
                          )
                              case final paymentNote?) ...[
                            const SizedBox(height: 8),
                            Text(
                              paymentNote,
                              style: AppTextStyles.bodyNormal.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (reservation.status == 'CANCELLED') ...[
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                humanizeCancellationReasonForInstructor(
                                  reservation.cancellationReason,
                                ),
                                style: AppTextStyles.bodyNormal.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Próximo paso',
                            style: AppTextStyles.heading.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reservation.nextActionHintInstructor,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _line(
                            'Fecha',
                            startsAt == null
                                ? 'Sin fecha'
                                : DateFormat(
                                    'EEEE d MMMM',
                                    'es',
                                  ).format(startsAt),
                          ),
                          _line(
                            'Horario',
                            startsAt == null || endsAt == null
                                ? 'Sin horario'
                                : '${DateFormat('HH:mm').format(startsAt)} - ${DateFormat('HH:mm').format(endsAt)}',
                          ),
                          _line(
                            'Duración',
                            '${reservation.durationMinutes} min',
                          ),
                          _line('Precio', reservation.priceLabel),
                          _line(
                            'Pago',
                            PremiumBookingUi.paymentShortLabel(
                              reservation.paymentStatus,
                            ),
                          ),
                          _line(
                            'Horario',
                            PremiumBookingUi.slotStatusLabel(
                              reservation.slotStatus,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PremiumBookingUi.policyHeadline(),
                            style: AppTextStyles.heading.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reservation.policyText,
                            style: AppTextStyles.bodyNormal,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            PremiumBookingUi.cancelDeadlineDetailText(
                              reservation.cancelDeadline,
                            ),
                            style: AppTextStyles.bodyNormal.copyWith(
                              color: reservation.canCancel
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            PremiumBookingUi.policyFooterHint(
                              canCancel: reservation.canCancel,
                            ),
                            style: AppTextStyles.bodyNormal.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  if (reservation.status == 'CONFIRMED') ...[
                    AppButton(
                      key: E2eKeys.instructorReservationDetailWhatsapp,
                      text: reservation.whatsappEnabled
                          ? 'Escribirle a ${reservation.whatsappCounterpartName ?? reservation.studentName} por WhatsApp'
                          : 'WhatsApp no disponible',
                      icon: Icons.chat_rounded,
                      onPressed: _submitting || !reservation.whatsappEnabled
                          ? null
                          : _openWhatsApp,
                      type: AppButtonType.whatsapp,
                    ),
                    if (!reservation.whatsappEnabled) ...[
                      const SizedBox(height: 8),
                      AppAvailabilityHint(
                        message:
                            PremiumBookingUi.whatsappUnavailableExplanation(
                          reservation.whatsappUnavailableReason,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                  AppButton(
                    key: E2eKeys.instructorReservationDetailPrimary,
                    text: PremiumBookingUi.nextActionInstructorPrimaryCta(
                      reservation.nextRecommendedAction,
                    ),
                    onPressed: _submitting ? null : _handlePrimaryAction,
                    isLoading: _submitting,
                    type: reservation.status == 'CONFIRMED'
                        ? AppButtonType.secondary
                        : AppButtonType.primary,
                  ),
                  if (_canMarkCompleted) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      key: E2eKeys.instructorReservationDetailComplete,
                      text: 'Marcar clase como completada',
                      onPressed: _submitting ? null : _completeClass,
                      type: AppButtonType.secondary,
                    ),
                  ],
                  const SizedBox(height: 10),
                  AppButton(
                    text: reservation.canCancel
                        ? 'Cancelar clase'
                        : 'No disponible para cancelar',
                    onPressed: _submitting || !reservation.canCancel
                        ? null
                        : _cancelReservation,
                    type: AppButtonType.outline,
                  ),
                  if (!reservation.canCancel) ...[
                    const SizedBox(height: 8),
                    AppAvailabilityHint(
                      message: PremiumBookingUi.cancelUnavailableExplanation(
                        status: reservation.status,
                        deadline: reservation.cancelDeadline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyNormal),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style:
                  AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorCompleteClassDialog extends StatefulWidget {
  final String studentName;

  const _InstructorCompleteClassDialog({required this.studentName});

  @override
  State<_InstructorCompleteClassDialog> createState() =>
      _InstructorCompleteClassDialogState();
}

class _InstructorCompleteClassDialogState
    extends State<_InstructorCompleteClassDialog> {
  final _notesController = TextEditingController();
  double _rating = 5.0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Text(
        'Completar clase',
        style: AppTextStyles.heading.copyWith(fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alumno: ${widget.studentName}',
            style: AppTextStyles.bodyNormal,
          ),
          const SizedBox(height: 16),
          Text(
            'Calificación del alumno',
            style: AppTextStyles.heading.copyWith(fontSize: 16),
          ),
          Slider(
            value: _rating,
            min: 1,
            max: 5,
            divisions: 4,
            label: _rating.toString(),
            onChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 16),
          AppInput(
            label: 'Notas de la clase',
            hint: 'Progreso, áreas de mejora.',
            controller: _notesController,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cerrar',
            style: AppTextStyles.bodyNormal.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        AppButton(
          text: 'Guardar',
          onPressed: () {
            Navigator.pop(context, {
              'notes': _notesController.text,
              'rating': _rating,
            });
          },
          type: AppButtonType.primary,
        ),
      ],
    );
  }
}
