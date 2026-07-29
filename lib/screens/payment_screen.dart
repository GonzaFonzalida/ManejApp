import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/screens/reservation_success_screen.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/payment_checkout_launcher.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';

class PaymentScreen extends StatefulWidget {
  static const routeName = '/payment';

  final int drivingClassId;
  final int amount;
  final String description;
  final String? payerEmail;
  final String? preferenceId;
  final String? initPoint;

  const PaymentScreen({
    super.key,
    required this.drivingClassId,
    required this.amount,
    required this.description,
    this.payerEmail,
    this.preferenceId,
    this.initPoint,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  String? _preferenceId;
  String? _initPoint;
  String _statusMessage = 'Todavía no iniciaste el pago';

  @override
  void initState() {
    super.initState();
    if (widget.drivingClassId <= 0) {
      _statusMessage =
          'Reserva inválida. Volvé a reservar desde el calendario.';
      return;
    }
    _preferenceId = widget.preferenceId;
    _initPoint = widget.initPoint;

    if (_initPoint != null && _initPoint!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openExistingCheckout();
      });
    }
  }

  Future<void> _openExistingCheckout() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Abriendo Mercado Pago…';
    });
    try {
      final opened = await openMercadoPagoCheckout(_initPoint!);
      if (!mounted) return;
      if (!opened) {
        setState(() => _statusMessage = 'No se pudo abrir Mercado Pago.');
        return;
      }
      await _navigateToConfirmation(paymentOpened: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigateToConfirmation({required bool paymentOpened}) async {
    Map<String, dynamic>? reservation;
    try {
      reservation = await ApiService.getStudentReservationDetailPremium(
        widget.drivingClassId.toString(),
      );
    } catch (_) {
      reservation = null;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReservationSuccessScreen(
          reservationId: widget.drivingClassId,
          reservation: reservation,
          paymentOpened: paymentOpened,
          preferenceId: _preferenceId,
        ),
      ),
    );
  }

  Future<void> _createPreferenceAndOpen() async {
    if (widget.drivingClassId <= 0) {
      AppFeedback.showError(context, 'No hay una reserva válida para pagar.');
      return;
    }

    setState(() {
      _loading = true;
      _statusMessage = 'Preparando el pago…';
    });

    try {
      final preference = await ApiService.createBookingPaymentPreference(
          widget.drivingClassId);
      _initPoint = preference.initPoint;
      _preferenceId = preference.preferenceId;

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Listo. Abrimos Mercado Pago…';
      });

      final opened = await openMercadoPagoCheckout(preference.initPoint);
      if (!mounted) return;

      if (!opened) {
        setState(() {
          _statusMessage = 'No se pudo abrir Mercado Pago.';
        });
        AppFeedback.showError(context, 'No se pudo abrir Mercado Pago.');
        return;
      }

      await _navigateToConfirmation(paymentOpened: true);
    } catch (e) {
      if (mounted) {
        final msg = humanizeApiError(e);
        setState(() {
          _statusMessage = msg;
        });
        AppFeedback.showError(context, msg);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _checkStatus() async {
    if (widget.drivingClassId <= 0) return;
    setState(() {
      _loading = true;
      _statusMessage = 'Consultando estado de la reserva…';
    });
    try {
      final result =
          await ApiService.mpGetPaymentStatus(widget.drivingClassId.toString());
      if (!mounted) return;
      await _navigateToConfirmation(paymentOpened: false);
      if (!mounted) return;
      AppFeedback.showInfo(context, 'Estado actual: ${result.paymentStatus}');
    } catch (e) {
      setState(() {
        _statusMessage = humanizeApiError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invalidBooking = widget.drivingClassId <= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pago con Mercado Pago',
            style: AppTextStyles.heading.copyWith(fontSize: 18)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: ResponsiveScrollBody(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Detalle del pago', style: AppTextStyles.heading),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Clase', style: AppTextStyles.bodyLarge),
                      Text('#${widget.drivingClassId}',
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monto', style: AppTextStyles.bodyLarge),
                      Text('\$${widget.amount}',
                          style: AppTextStyles.heading.copyWith(
                              color: AppColors.secondary, fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(widget.description,
                      style: AppTextStyles.bodyNormal
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: AppTextStyles.bodyNormal.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_preferenceId != null) ...[
              const SizedBox(height: 12),
              Text('Ref: $_preferenceId',
                  style: AppTextStyles.bodyNormal
                      .copyWith(color: AppColors.textSecondary, fontSize: 12)),
            ],
            const SizedBox(height: 32),
            if (_loading)
              const CircularProgressIndicator(color: AppColors.primary)
            else ...[
              AppButton(
                text: 'Pagar con Mercado Pago',
                icon: Icons.payment,
                onPressed: invalidBooking ? null : _createPreferenceAndOpen,
                type: AppButtonType.primary,
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Consultar estado',
                icon: Icons.refresh,
                onPressed: invalidBooking ? null : _checkStatus,
                type: AppButtonType.outline,
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
