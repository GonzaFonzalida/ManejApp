import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/utils/app_formatters.dart';
import 'package:manejapp/models/instructor.dart';
import 'package:manejapp/models/payment_status_result.dart';
import 'package:manejapp/screens/reservation_success_screen.dart';
import 'package:manejapp/screens/student_reservation_detail_screen.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/reservation_status_education.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/context_help_card.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';
import 'package:manejapp/utils/payment_checkout_launcher.dart';

class ReservationReviewScreen extends StatefulWidget {
  final Instructor instructor;
  final Map<String, dynamic> slot;

  const ReservationReviewScreen({
    super.key,
    required this.instructor,
    required this.slot,
  });

  @override
  State<ReservationReviewScreen> createState() =>
      _ReservationReviewScreenState();
}

class _ReservationReviewScreenState extends State<ReservationReviewScreen> {
  Map<String, dynamic>? _preview;
  bool _loadingPreview = true;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() => _loadingPreview = true);
    try {
      final data =
          await ApiService.getReservationPreview(widget.slot['id'].toString());
      if (!mounted) return;
      setState(() => _preview = data);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  DateTime get _startsAt {
    final fromPreview = _preview?['startsAt']?.toString();
    if (fromPreview != null && fromPreview.isNotEmpty) {
      return DateTime.parse(fromPreview);
    }
    return DateTime.parse(widget.slot['startTime'].toString());
  }

  DateTime get _endsAt {
    final fromPreview = _preview?['endsAt']?.toString();
    if (fromPreview != null && fromPreview.isNotEmpty) {
      return DateTime.parse(fromPreview);
    }
    return DateTime.parse(widget.slot['endTime'].toString());
  }

  int get _durationMinutes {
    final val = _preview?['durationMinutes'];
    if (val is int) return val;
    return _endsAt.difference(_startsAt).inMinutes;
  }

  String get _priceLabel {
    final fromSummary =
        _preview?['priceSummary']?['estimatedTotalLabel']?.toString();
    if (fromSummary != null && fromSummary.isNotEmpty) return fromSummary;
    final amount = _preview?['priceSummary']?['amount'];
    if (amount is num) return AppFormatters.ars(amount);
    final fallback =
        ((widget.instructor.effectiveHourlyRate / 60) * _durationMinutes)
            .round();
    return AppFormatters.ars(fallback);
  }

  String get _policyText {
    final text = _preview?['policySummary']?['text']?.toString();
    if (text != null && text.isNotEmpty) return text;
    return 'Cancelación permitida hasta 6h antes. Reprogramación hasta 12h antes, según disponibilidad.';
  }

  Future<void> _confirmAndBook() async {
    final canReserveNow = _preview?['canReserveNow'];
    if (canReserveNow is bool && !canReserveNow) {
      AppFeedback.showInfo(
        context,
        _preview?['availabilityMessage']?.toString() ??
            'Este horario ya no está disponible',
      );
      return;
    }

    setState(() => _confirming = true);
    try {
      final reserveResult =
          await ApiService.reserveSlotBySlotId(widget.slot['id'].toString());
      final bookingId = reserveResult['bookingId'] as int?;
      if (bookingId == null) {
        throw Exception('No se recibió bookingId en la reserva');
      }

      BookingPaymentPreference preference;
      try {
        preference = await ApiService.createBookingPaymentPreference(bookingId);
      } catch (e) {
        if (!mounted) return;
        AppFeedback.showError(
          context,
          messageForPaymentPreferenceError(e, bookingCreated: true),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                StudentReservationDetailScreen(reservationId: bookingId),
          ),
        );
        return;
      }

      final initPoint = preference.initPoint;

      Map<String, dynamic>? reservation;
      try {
        reservation = await ApiService.getStudentReservationDetailPremium(
            bookingId.toString());
      } catch (_) {
        reservation = null;
      }

      bool paymentOpened = false;
      if (initPoint.isNotEmpty) {
        paymentOpened = await openMercadoPagoCheckout(initPoint);
        if (!paymentOpened && mounted) {
          AppFeedback.showError(
            context,
            'No se pudo abrir Mercado Pago. Podés pagar desde el detalle de tu reserva.',
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReservationSuccessScreen(
            reservationId: bookingId,
            reservation: reservation,
            paymentOpened: paymentOpened,
            preferenceId: preference.preferenceId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      if (message.contains('HTTP 409') ||
          message.toLowerCase().contains('no disponible')) {
        AppFeedback.showInfo(
          context,
          'Este horario ya no está disponible. Elegí otro slot para continuar.',
        );
      } else {
        AppFeedback.showError(context, humanizeApiError(e));
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instructorName =
        '${widget.instructor.user?.name ?? ''} ${widget.instructor.user?.surname ?? ''}'
            .trim();
    final zone = _preview?['location']?['zoneLabel']?.toString() ??
        _preview?['location']?['addressText']?.toString() ??
        widget.instructor.user?.location ??
        'Ubicación a confirmar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Revisá tu reserva',
            style: AppTextStyles.heading.copyWith(fontSize: 20)),
      ),
      body: _loadingPreview
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ResponsiveScrollBody(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Instructor', style: AppTextStyles.bodyNormal),
                        const SizedBox(height: 6),
                        Text(instructorName,
                            style:
                                AppTextStyles.heading.copyWith(fontSize: 18)),
                        const SizedBox(height: 12),
                        Text('Zona', style: AppTextStyles.bodyNormal),
                        const SizedBox(height: 4),
                        Text(zone, style: AppTextStyles.bodyLarge),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _line('Fecha',
                            DateFormat('EEEE d MMMM', 'es').format(_startsAt)),
                        _line('Horario',
                            '${DateFormat('HH:mm').format(_startsAt)} - ${DateFormat('HH:mm').format(_endsAt)}'),
                        _line('Duración', '$_durationMinutes min'),
                        _line('Precio total', _priceLabel, highlighted: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Política',
                            style:
                                AppTextStyles.heading.copyWith(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(_policyText, style: AppTextStyles.bodyNormal),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ContextHelpCard(
                    title: '¿Cómo se confirma mi reserva?',
                    steps:
                        ReservationStatusEducation.reservationConfirmationSteps,
                    icon: Icons.help_outline_rounded,
                  ),
                  const SizedBox(height: 22),
                  AppButton(
                    text: 'Confirmar y continuar al pago',
                    onPressed: _confirming ? null : _confirmAndBook,
                    isLoading: _confirming,
                    type: AppButtonType.primary,
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    text: 'Elegir otro horario',
                    onPressed:
                        _confirming ? null : () => Navigator.pop(context),
                    type: AppButtonType.outline,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _line(String label, String value, {bool highlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(label, style: AppTextStyles.bodyNormal),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.bodyLarge.copyWith(
                color: highlighted ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
