import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_empty_state.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/screens/home_screen.dart';
import 'package:manejapp/screens/student_reservation_detail_screen.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/app_formatters.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/skeleton_loader.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import '../models/payment.dart';
import '../models/driving_class.dart';

const storage = appSecureStorage;

String _paymentStatusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return 'Pagado';
    case 'pending':
      return 'Pendiente';
    case 'failed':
      return 'Fallido';
    default:
      return status;
  }
}

String _paymentMethodLabel(String method) {
  switch (method.toLowerCase()) {
    case 'mercadopago':
      return 'Mercado Pago';
    case 'cash':
      return 'Efectivo';
    case 'transfer':
      return 'Transferencia';
    default:
      return method;
  }
}

String _shortRef(String id) {
  final t = id.trim();
  if (t.length <= 10) return '#$t';
  return '#${t.substring(0, 8)}…';
}

class StudentPaymentsScreen extends StatefulWidget {
  const StudentPaymentsScreen({super.key});

  @override
  State<StudentPaymentsScreen> createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Payment> _allPayments = [];
  List<Payment> _paidPayments = [];
  List<Payment> _pendingPayments = [];
  List<Payment> _failedPayments = [];
  bool _isLoading = true;
  String? _loadError;
  double _totalPaid = 0;
  double _totalPending = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPayments(silent: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments({bool silent = true}) async {
    if (!silent) {
      setState(() {
        _loadError = null;
        _isLoading = true;
      });
    } else if (mounted) {
      setState(() => _loadError = null);
    }
    try {
      final token = await storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadError = 'No encontramos tu sesión. Volvé a iniciar sesión.';
          });
        }
        return;
      }
      // GET /classes ya filtra por rol (solo clases del usuario autenticado).
      final classes = await ApiService.getDrivingClasses();
      final studentClasses = classes
          .map((c) => DrivingClass.fromJson(c as Map<String, dynamic>))
          .toList();

      final paymentsList = await ApiService.getPayments();

      _allPayments = paymentsList
          .where((p) =>
              studentClasses.any((c) => c.id == (p as Map)['drivingClassId']))
          .map((p) => Payment.fromJson(p as Map<String, dynamic>))
          .toList();

      // Filtrar por estado
      _paidPayments = _allPayments.where((p) => p.status == 'paid').toList();
      _pendingPayments =
          _allPayments.where((p) => p.status == 'pending').toList();
      _failedPayments =
          _allPayments.where((p) => p.status == 'failed').toList();

      // Calcular totales
      _totalPaid = _paidPayments.fold(0, (sum, p) => sum + p.amount);
      _totalPending = _pendingPayments.fold(0, (sum, p) => sum + p.amount);

      // Ordenar por fecha
      _allPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _paidPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _pendingPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _failedPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      debugPrint('Error cargando pagos: $e');
      if (!mounted) return;
      if (silent) {
        AppFeedback.showError(context, humanizeApiError(e));
      } else {
        setState(() {
          _isLoading = false;
          _loadError = humanizeApiError(e);
        });
      }
    }
  }

  Future<void> _openReservationToPay(Payment payment) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StudentReservationDetailScreen(
            reservationId: payment.drivingClassId),
      ),
    );
    if (mounted) await _loadPayments(silent: true);
  }

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => PaymentDetailsDialog(payment: payment),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mis pagos',
            style: AppTextStyles.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? _buildLoadingBody()
          : _loadError != null
              ? Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AppErrorState(
                      title: 'No pudimos cargar tus pagos',
                      message: _loadError,
                      onRetry: () => _loadPayments(silent: false),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        'Resumen',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    // Resumen de pagos
                    Semantics(
                      label:
                          'Total pagado ${AppFormatters.ars(_totalPaid)}, pendiente ${AppFormatters.ars(_totalPending)}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildSummaryItem(
                                  'Pagado',
                                  AppFormatters.ars(_totalPaid),
                                  AppColors.success,
                                  Icons.check_circle,
                                ),
                              ),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: AppColors.surfaceLighter),
                              Expanded(
                                child: _buildSummaryItem(
                                  'Pendiente',
                                  AppFormatters.ars(_totalPending),
                                  AppColors.warning,
                                  Icons.schedule,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      isScrollable: true,
                      labelStyle: AppTextStyles.bodyNormal
                          .copyWith(fontWeight: FontWeight.bold),
                      tabs: [
                        Tab(text: 'Todos (${_allPayments.length})'),
                        Tab(text: 'Pagados (${_paidPayments.length})'),
                        Tab(text: 'Pendientes (${_pendingPayments.length})'),
                        Tab(text: 'Fallidos (${_failedPayments.length})'),
                      ],
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _loadPayments(silent: true),
                        color: AppColors.primary,
                        backgroundColor: AppColors.surfaceLight,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPaymentsList(_allPayments),
                            _buildPaymentsList(_paidPayments),
                            _buildPaymentsList(_pendingPayments),
                            _buildPaymentsList(_failedPayments),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoadingBody() {
    Widget listRowPlaceholder(BuildContext ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            const SkeletonLoader(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: double.infinity,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: MediaQuery.sizeOf(ctx).width * 0.6,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SkeletonLoader(
                  width: 160,
                  height: 22,
                  borderRadius: BorderRadius.circular(6)),
              const SizedBox(height: 20),
              const CardSkeletonLoader(),
              const SizedBox(height: 20),
              Row(
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SkeletonLoader(
                        width: 72,
                        height: 28,
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Builder(builder: listRowPlaceholder),
              Builder(builder: listRowPlaceholder),
              Builder(builder: listRowPlaceholder),
              Builder(builder: listRowPlaceholder),
              Builder(builder: listRowPlaceholder),
              Builder(builder: listRowPlaceholder),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
      String title, String amount, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(amount,
            style: AppTextStyles.heading.copyWith(fontSize: 18, color: color)),
        Text(title,
            style: AppTextStyles.bodyNormal
                .copyWith(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildPaymentsList(List<Payment> payments) {
    if (payments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        children: [
          AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No hay pagos en esta categoría',
            subtitle:
                'Cuando reserves una clase y pagues con Mercado Pago, vas a ver el historial acá.',
            actionLabel: 'Buscar instructores',
            onAction: () => Navigator.pushNamed(context, HomeScreen.routeName),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final statusColor = _getStatusColor(payment.status);
    final canRetry = payment.status == 'failed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => _showPaymentDetails(payment),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppFormatters.ars(payment.amount),
                        style: AppTextStyles.heading.copyWith(fontSize: 18),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm', 'es')
                            .format(payment.createdAt),
                        style: AppTextStyles.bodyNormal.copyWith(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _paymentStatusLabel(payment.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_paymentMethodLabel(payment.method),
                    style: AppTextStyles.bodyNormal.copyWith(fontSize: 13)),
                const SizedBox(width: 16),
                if (payment.transactionId != null) ...[
                  Icon(Icons.receipt, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _shortRef(payment.transactionId!),
                      style: AppTextStyles.bodyNormal.copyWith(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (canRetry) ...[
              const SizedBox(height: 12),
              Semantics(
                label: 'Ir a la reserva para reintentar el pago',
                child: AppButton(
                  text: 'Ir a la reserva para pagar',
                  icon: Icons.open_in_new,
                  onPressed: () => _openReservationToPay(payment),
                  type: AppButtonType.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class PaymentDetailsDialog extends StatelessWidget {
  final Payment payment;

  const PaymentDetailsDialog({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      title: Text('Detalle del pago',
          style: AppTextStyles.heading.copyWith(fontSize: 18)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Monto', AppFormatters.ars(payment.amount)),
          _buildDetailRow('Estado', _paymentStatusLabel(payment.status)),
          _buildDetailRow('Método', _paymentMethodLabel(payment.method)),
          if (payment.transactionId != null)
            _buildDetailRow('ID de transacción', payment.transactionId!),
          _buildDetailRow('Fecha',
              DateFormat('dd/MM/yyyy HH:mm', 'es').format(payment.createdAt)),
          if (payment.description != null)
            _buildDetailRow('Descripción', payment.description!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar',
              style: AppTextStyles.bodyNormal
                  .copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:',
                style: AppTextStyles.bodyNormal
                    .copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyNormal),
          ),
        ],
      ),
    );
  }
}
