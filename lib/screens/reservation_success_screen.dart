import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/config/premium_booking_ui.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import 'package:manejapp/models/payment_status_result.dart';
import 'package:manejapp/screens/student_dashboard_screen.dart';
import 'package:manejapp/screens/student_reservation_detail_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/reservation_status_education.dart';
import 'package:manejapp/widgets/design/context_help_card.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';

typedef PaymentStatusFetcher = Future<PaymentStatusResult> Function(
    String identifier);

class ReservationSuccessScreen extends StatefulWidget {
  final int reservationId;
  final Map<String, dynamic>? reservation;
  final bool paymentOpened;
  final String? preferenceId;

  /// Solo para tests: reemplaza la consulta a ApiService.
  final PaymentStatusFetcher? statusFetcher;

  /// Desactiva el timer periódico (útil en widget tests).
  final bool autoPoll;

  const ReservationSuccessScreen({
    super.key,
    required this.reservationId,
    required this.reservation,
    required this.paymentOpened,
    this.preferenceId,
    this.statusFetcher,
    this.autoPoll = true,
  });

  @override
  State<ReservationSuccessScreen> createState() =>
      _ReservationSuccessScreenState();
}

class _ReservationSuccessScreenState extends State<ReservationSuccessScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 3);
  static const _initialPollBudget = Duration(seconds: 60);

  PaymentConfirmationState _state = PaymentConfirmationState.checking;
  Map<String, dynamic>? _reservation;
  PaymentStatusResult? _lastStatus;
  Timer? _pollTimer;
  DateTime? _pollStartedAt;
  bool _pollingActive = false;
  bool _manualRefreshing = false;

  @override
  void initState() {
    super.initState();
    _reservation = widget.reservation;
    WidgetsBinding.instance.addObserver(this);
    if (widget.autoPoll) {
      _startPolling();
    } else {
      unawaited(_checkStatus(manual: false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _shouldKeepPolling) {
      unawaited(_checkStatus(manual: false));
    }
  }

  bool get _shouldKeepPolling =>
      _state == PaymentConfirmationState.checking ||
      _state == PaymentConfirmationState.pending;

  String get _statusIdentifier => widget.reservationId.toString();

  void _startPolling() {
    _pollStartedAt ??= DateTime.now();
    _pollTimer?.cancel();
    unawaited(_checkStatus(manual: false));
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!_shouldKeepPolling) {
        _stopPolling();
        return;
      }
      final started = _pollStartedAt;
      if (started != null &&
          DateTime.now().difference(started) >= _initialPollBudget) {
        _stopPolling();
        if (mounted && _state == PaymentConfirmationState.checking) {
          setState(() => _state = PaymentConfirmationState.pending);
        }
        return;
      }
      unawaited(_checkStatus(manual: false));
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollingActive = false;
  }

  Future<PaymentStatusResult> _fetchStatus() {
    final fetcher = widget.statusFetcher;
    if (fetcher != null) {
      return fetcher(_statusIdentifier);
    }
    return ApiService.mpGetPaymentStatus(_statusIdentifier);
  }

  Future<void> _refreshReservationDetail() async {
    try {
      final detail = await ApiService.getStudentReservationDetailPremium(
        widget.reservationId.toString(),
      );
      if (!mounted) return;
      setState(() => _reservation = detail);
    } catch (_) {
      // Mantener datos previos si falla el detalle premium.
    }
  }

  Future<void> _checkStatus({required bool manual}) async {
    if (!mounted) return;
    if (_pollingActive && !manual) return;

    _pollingActive = true;
    if (manual) {
      setState(() => _manualRefreshing = true);
    }

    try {
      final status = await _fetchStatus();
      if (!mounted) return;

      if (widget.statusFetcher == null) {
        await _refreshReservationDetail();
        if (!mounted) return;
      }

      final reservationStatus = _reservation?['status']?.toString();
      final nextState =
          status.resolveState(reservationStatus: reservationStatus);

      setState(() {
        _lastStatus = status;
        _state = nextState;
      });

      if (!_shouldKeepPolling) {
        _stopPolling();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = PaymentConfirmationState.networkError;
      });
      _stopPolling();
    } finally {
      _pollingActive = false;
      if (mounted && manual) {
        setState(() => _manualRefreshing = false);
      }
    }
  }

  Future<void> _onManualRefresh() async {
    _pollStartedAt = DateTime.now();
    if (_state == PaymentConfirmationState.networkError) {
      setState(() => _state = PaymentConfirmationState.checking);
    }
    _startPolling();
    await _checkStatus(manual: true);
  }

  String _safeString(dynamic value, String fallback) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return fallback;
    return text;
  }

  String get _scheduleText {
    final startsAtRaw = _reservation?['startsAt']?.toString();
    final startsAt =
        startsAtRaw != null ? DateTime.tryParse(startsAtRaw) : null;
    if (startsAt == null) return 'Tu clase fue registrada correctamente.';
    return DateFormat('EEEE d MMMM · HH:mm', 'es').format(startsAt);
  }

  _UiCopy get _copy {
    switch (_state) {
      case PaymentConfirmationState.checking:
        return _UiCopy(
          title: 'Confirmando pago',
          headline: 'Estamos confirmando tu pago…',
          body: widget.paymentOpened
              ? 'Volvimos de Mercado Pago. Esto puede tardar unos segundos.'
              : 'Consultando el estado de tu reserva…',
          icon: Icons.hourglass_top,
          iconColor: AppColors.warning,
          showSpinner: true,
        );
      case PaymentConfirmationState.confirmed:
        return _UiCopy(
          title: 'Reserva confirmada',
          headline: 'Tu reserva fue confirmada',
          body: 'El pago se acreditó correctamente. Te esperamos en la clase.',
          icon: Icons.check_circle,
          iconColor: AppColors.success,
        );
      case PaymentConfirmationState.pending:
        return _UiCopy(
          title: 'Pago pendiente',
          headline: 'Pago pendiente de confirmación',
          body:
              'Tu pago todavía está pendiente de confirmación. Puede tardar unos minutos. Podés actualizar el estado desde esta pantalla o revisar tus reservas más tarde.',
          icon: Icons.schedule,
          iconColor: AppColors.warning,
        );
      case PaymentConfirmationState.failed:
        return _UiCopy(
          title: 'Pago no confirmado',
          headline: 'El pago no se pudo confirmar',
          body:
              'El pago no se pudo confirmar. Podés intentar nuevamente desde la reserva si sigue disponible.',
          icon: Icons.error_outline,
          iconColor: AppColors.error,
        );
      case PaymentConfirmationState.manualReview:
        return _UiCopy(
          title: 'Pago en revisión',
          headline: 'Recibimos información del pago',
          body:
              'Recibimos información del pago, pero necesitamos revisarlo manualmente. No hagas otro pago por ahora.',
          icon: Icons.support_agent,
          iconColor: AppColors.warning,
        );
      case PaymentConfirmationState.networkError:
        return _UiCopy(
          title: 'Estado no disponible',
          headline: 'No pudimos consultar el estado',
          body:
              'No pudimos consultar el estado en este momento. Si el pago fue realizado, puede confirmarse en unos minutos.',
          icon: Icons.cloud_off,
          iconColor: AppColors.textSecondary,
        );
    }
  }

  void _goToReservations() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      StudentDashboardScreen.routeName,
      (_) => false,
    );
  }

  void _goToDetail() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StudentReservationDetailScreen(
          reservationId: widget.reservationId,
        ),
      ),
    );
  }

  void _retryPayment() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StudentReservationDetailScreen(
          reservationId: widget.reservationId,
        ),
      ),
    );
  }

  String? get _educationHint {
    if (_state == PaymentConfirmationState.manualReview) {
      return ReservationStatusEducation.successScreenHint('manualReview');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    final status = _safeString(_reservation?['status'], 'PENDING_PAYMENT');
    final paymentStatus = _lastStatus?.paymentStatus ??
        _safeString(_reservation?['paymentStatus'], 'pending');
    final action = _safeString(
      _reservation?['nextRecommendedAction'],
      'CHECK_RESERVATION_STATUS',
    );
    final policyText = _safeString(
      _reservation?['policySummary']?['text'],
      'Revisá las políticas desde el detalle de tu reserva.',
    );
    final cancelDeadline = _reservation?['cancelDeadline']?.toString();
    final cancelDeadlineText = cancelDeadline == null
        ? '—'
        : DateFormat('d MMMM · HH:mm', 'es')
            .format(DateTime.parse(cancelDeadline));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(copy.title,
            style: AppTextStyles.heading.copyWith(fontSize: 20)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (copy.showSpinner)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  )
                                else
                                  Icon(copy.icon,
                                      color: copy.iconColor, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    copy.headline,
                                    style: AppTextStyles.heading
                                        .copyWith(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(copy.body, style: AppTextStyles.bodyNormal),
                            const SizedBox(height: 14),
                            Text(
                              _scheduleText,
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text('Reserva #${widget.reservationId}',
                                style: AppTextStyles.bodyNormal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            _line('Reserva',
                                PremiumBookingUi.statusLabel(status)),
                            _line(
                                'Pago',
                                PremiumBookingUi.paymentShortLabel(
                                    paymentStatus)),
                            _line(
                              'Próximo paso',
                              PremiumBookingUi.nextActionStudentCard(action),
                            ),
                            _line('Cancelar hasta', cancelDeadlineText),
                          ],
                        ),
                      ),
                      if (_educationHint case final hint?) ...[
                        const SizedBox(height: 14),
                        ContextHelpCard(
                          title: 'Qué hacer ahora',
                          body: hint,
                          icon: Icons.info_outline_rounded,
                        ),
                      ],
                      const SizedBox(height: 14),
                      AppCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              PremiumBookingUi.policyHeadline(),
                              style:
                                  AppTextStyles.heading.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(policyText, style: AppTextStyles.bodyNormal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (_state == PaymentConfirmationState.confirmed) ...[
                AppButton(
                  key: E2eKeys.reservationSuccessGoToList,
                  text: 'Ver mis reservas',
                  onPressed: _goToReservations,
                  type: AppButtonType.primary,
                ),
                const SizedBox(height: 10),
                AppButton(
                  text: 'Ver detalle',
                  onPressed: _goToDetail,
                  type: AppButtonType.secondary,
                ),
              ] else if (_state == PaymentConfirmationState.pending ||
                  _state == PaymentConfirmationState.networkError ||
                  _state == PaymentConfirmationState.checking) ...[
                AppButton(
                  key: E2eKeys.reservationSuccessRefreshStatus,
                  text: 'Actualizar estado',
                  onPressed: _manualRefreshing ? null : _onManualRefresh,
                  isLoading: _manualRefreshing,
                  type: AppButtonType.primary,
                ),
                const SizedBox(height: 10),
                AppButton(
                  key: E2eKeys.reservationSuccessGoToList,
                  text: 'Ver mis reservas',
                  onPressed: _goToReservations,
                  type: AppButtonType.outline,
                ),
              ] else if (_state == PaymentConfirmationState.failed) ...[
                AppButton(
                  text: 'Intentar de nuevo',
                  onPressed: _retryPayment,
                  type: AppButtonType.primary,
                ),
                const SizedBox(height: 10),
                AppButton(
                  key: E2eKeys.reservationSuccessGoToList,
                  text: 'Volver a mis reservas',
                  onPressed: _goToReservations,
                  type: AppButtonType.outline,
                ),
              ] else if (_state == PaymentConfirmationState.manualReview) ...[
                AppButton(
                  key: E2eKeys.reservationSuccessGoToList,
                  text: 'Ver mis reservas',
                  onPressed: _goToReservations,
                  type: AppButtonType.primary,
                ),
                const SizedBox(height: 10),
                AppButton(
                  text: 'Ver detalle',
                  onPressed: _goToDetail,
                  type: AppButtonType.outline,
                ),
              ],
            ],
          ),
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

class _UiCopy {
  final String title;
  final String headline;
  final String body;
  final IconData icon;
  final Color iconColor;
  final bool showSpinner;

  const _UiCopy({
    required this.title,
    required this.headline,
    required this.body,
    required this.icon,
    required this.iconColor,
    this.showSpinner = false,
  });
}
