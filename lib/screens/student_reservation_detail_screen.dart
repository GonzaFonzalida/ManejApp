import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/config/premium_booking_ui.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import 'package:manejapp/models/premium_reservation.dart';
import 'package:manejapp/models/payment_status_result.dart';
import 'package:manejapp/screens/reschedule_class_screen.dart';
import 'package:manejapp/screens/reservation_success_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/confirmation_dialog.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_availability_hint.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/premium_async_states.dart';
import 'package:manejapp/utils/cancellation_reason_copy.dart';
import 'package:manejapp/utils/reservation_status_education.dart';
import 'package:manejapp/widgets/design/context_help_card.dart';
import 'package:manejapp/utils/payment_checkout_launcher.dart';
import 'package:manejapp/utils/whatsapp.dart';

class StudentReservationDetailScreen extends StatefulWidget {
  final int reservationId;

  const StudentReservationDetailScreen({
    super.key,
    required this.reservationId,
  });

  @override
  State<StudentReservationDetailScreen> createState() =>
      _StudentReservationDetailScreenState();
}

class _StudentReservationDetailScreenState
    extends State<StudentReservationDetailScreen> {
  PremiumReservation? _reservation;
  bool _loading = true;
  String? _loadError;
  bool _submitting = false;
  bool _refreshingStatus = false;
  String? _statusBanner;

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
      final data = await ApiService.getStudentReservationDetailPremium(
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

  Future<void> _refreshPaymentStatus() async {
    setState(() {
      _refreshingStatus = true;
      _statusBanner = null;
    });
    try {
      final status =
          await ApiService.mpGetPaymentStatus(widget.reservationId.toString());
      await _loadDetail();
      if (!mounted) return;
      final reservation = _reservation;
      final state = status.resolveState(reservationStatus: reservation?.status);
      setState(() {
        _statusBanner = _bannerForState(state, reservation);
      });
      if (state == PaymentConfirmationState.confirmed) {
        AppFeedback.showSuccess(context, 'Tu reserva fue confirmada.');
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _refreshingStatus = false);
    }
  }

  String? _bannerForState(
      PaymentConfirmationState state, PremiumReservation? reservation) {
    switch (state) {
      case PaymentConfirmationState.confirmed:
        return 'Tu reserva está confirmada.';
      case PaymentConfirmationState.pending:
        return 'El pago sigue pendiente de confirmación. Podés actualizar el estado en unos minutos.';
      case PaymentConfirmationState.manualReview:
        return 'Tu pago está en revisión. No intentes pagar de nuevo por ahora.';
      case PaymentConfirmationState.failed:
        if (reservation?.status == 'CANCELLED') {
          return 'La reserva fue cancelada. Si el cupo sigue disponible, podés reservar nuevamente.';
        }
        return 'El pago no se pudo confirmar. Podés reintentar si el hold sigue activo.';
      case PaymentConfirmationState.networkError:
        return 'No pudimos consultar el estado. Intentá actualizar en unos segundos.';
      case PaymentConfirmationState.checking:
        return null;
    }
  }

  bool get _canRefreshPaymentStatus {
    final reservation = _reservation;
    if (reservation == null) return false;
    if (reservation.status == 'CONFIRMED') return true;
    if (reservation.paymentStatus == 'manual_review') return true;
    if (reservation.status == 'PENDING_PAYMENT') return true;
    if (reservation.status == 'CANCELLED') return true;
    return false;
  }

  bool get _canRetryPayment {
    final reservation = _reservation;
    if (reservation == null) return false;
    if (reservation.paymentStatus == 'manual_review') return false;
    return reservation.nextRecommendedAction == 'COMPLETE_PAYMENT';
  }

  Future<void> _handlePrimaryAction() async {
    final reservation = _reservation;
    if (reservation == null) return;

    if (_canRetryPayment) {
      setState(() => _submitting = true);
      try {
        final preference =
            await ApiService.createBookingPaymentPreference(reservation.id);
        final opened = await openMercadoPagoCheckout(preference.initPoint);
        if (!mounted) return;
        if (!opened) {
          AppFeedback.showError(context, 'No se pudo abrir Mercado Pago.');
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReservationSuccessScreen(
              reservationId: reservation.id,
              reservation: reservation.raw,
              paymentOpened: true,
              preferenceId: preference.preferenceId,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        AppFeedback.showError(
          context,
          humanizeApiError(e),
        );
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    await _loadDetail();
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
      title: 'Cancelar reserva',
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
      AppFeedback.showSuccess(context, 'Reserva cancelada correctamente.');
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _rescheduleReservation() async {
    final reservation = _reservation;
    if (reservation == null) return;

    final instructorId = reservation.instructorId;
    if (instructorId == null) {
      AppFeedback.showError(context, 'No pudimos identificar al instructor.');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RescheduleClassScreen(
          bookingId: reservation.id,
          instructorId: instructorId,
          durationMinutes: reservation.durationMinutes,
        ),
      ),
    );

    if (result == true) {
      await _loadDetail();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const BookingDetailLoadingScaffold(title: 'Detalle de reserva');
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
              title: 'No pudimos abrir esta reserva',
              message: _loadError,
              onRetry: _loadDetail,
              retryLabel: 'Reintentar',
              retryButtonKey: E2eKeys.studentReservationDetailRetry,
            ),
          ),
        ),
      );
    }

    final startsAt = reservation.startsAt;
    final endsAt = reservation.endsAt;
    final statusColor = PremiumBookingUi.statusColor(reservation.status);
    final payAccent = PremiumBookingUi.paymentAccent(reservation.paymentStatus);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Detalle de reserva',
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                reservation.instructorName,
                                style: AppTextStyles.heading.copyWith(
                                  fontSize: 18,
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
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                        ],
                      ),
                    ),
                    if (_statusBanner == null) ...[
                      if (ReservationStatusEducation.studentDetailGuidance(
                        status: reservation.status,
                        paymentStatus: reservation.paymentStatus,
                      )
                          case final guidance?) ...[
                        const SizedBox(height: 12),
                        ContextHelpCard(
                          title: 'Qué significa este estado',
                          body: guidance,
                          icon: Icons.info_outline_rounded,
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    if (reservation.status == 'CANCELLED')
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                humanizeCancellationReason(
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
                    if (reservation.status == 'CANCELLED')
                      const SizedBox(height: 12),
                    if (_statusBanner != null)
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _statusBanner!,
                          style: AppTextStyles.bodyNormal.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_statusBanner != null) const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Próximo paso',
                            style: AppTextStyles.heading.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            reservation.nextActionHintStudent,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
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
                      key: E2eKeys.studentReservationDetailWhatsapp,
                      text: reservation.whatsappEnabled
                          ? 'Escribirle a ${reservation.whatsappCounterpartName ?? reservation.instructorName} por WhatsApp'
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
                    key: E2eKeys.studentReservationDetailPrimary,
                    text: reservation.paymentStatus == 'manual_review'
                        ? 'Pago en revisión'
                        : PremiumBookingUi.nextActionStudentPrimaryCta(
                            reservation.nextRecommendedAction,
                          ),
                    onPressed: _submitting ||
                            (reservation.nextRecommendedAction ==
                                    'COMPLETE_PAYMENT' &&
                                !_canRetryPayment)
                        ? null
                        : _handlePrimaryAction,
                    isLoading: _submitting,
                    type: reservation.status == 'CONFIRMED'
                        ? AppButtonType.secondary
                        : AppButtonType.primary,
                  ),
                  if (_canRefreshPaymentStatus) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      text: 'Actualizar estado',
                      onPressed:
                          _refreshingStatus ? null : _refreshPaymentStatus,
                      isLoading: _refreshingStatus,
                      type: AppButtonType.secondary,
                    ),
                  ],
                  if (reservation.canReschedule) ...[
                    const SizedBox(height: 10),
                    AppButton(
                      text: 'Reprogramar clase',
                      onPressed: _submitting ? null : _rescheduleReservation,
                      type: AppButtonType.secondary,
                    ),
                  ],
                  const SizedBox(height: 10),
                  AppButton(
                    key: E2eKeys.studentReservationDetailCancel,
                    text: reservation.canCancel
                        ? 'Cancelar reserva'
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
