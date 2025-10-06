import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/payment.dart';
import '../models/driving_class.dart';

const storage = FlutterSecureStorage();

class StudentPaymentsScreen extends StatefulWidget {
  const StudentPaymentsScreen({super.key});

  @override
  State<StudentPaymentsScreen> createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Payment> _allPayments = [];
  List<Payment> _paidPayments = [];
  List<Payment> _pendingPayments = [];
  List<Payment> _failedPayments = [];
  bool _isLoading = true;
  double _totalPaid = 0;
  double _totalPending = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    try {
      final userId = await storage.read(key: 'user_id');
      if (userId != null) {
        // Obtener clases del estudiante
        final classes = await ApiService.getDrivingClasses();
        final studentClasses = classes
            .where((c) => c['studentId'].toString() == userId)
            .map((c) => DrivingClass.fromJson(c))
            .toList();

        // Obtener pagos relacionados con las clases del estudiante
        final payments = await ApiService.getPayments();
        _allPayments = payments
            .where((p) => studentClasses.any((c) => c.id == p['drivingClassId']))
            .map((p) => Payment.fromJson(p))
            .toList();

        // Filtrar por estado
        _paidPayments = _allPayments.where((p) => p.status == 'paid').toList();
        _pendingPayments = _allPayments.where((p) => p.status == 'pending').toList();
        _failedPayments = _allPayments.where((p) => p.status == 'failed').toList();

        // Calcular totales
        _totalPaid = _paidPayments.fold(0, (sum, p) => sum + p.amount);
        _totalPending = _pendingPayments.fold(0, (sum, p) => sum + p.amount);

        // Ordenar por fecha
        _allPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _paidPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _pendingPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _failedPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('Error cargando pagos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando pagos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _retryPayment(Payment payment) async {
    try {
      // Aquí podrías implementar la lógica para reintentar el pago
      // Por ahora, solo mostramos un mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Función de reintento de pago próximamente'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reintentando pago: $e')),
        );
      }
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Mis Pagos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Resumen de pagos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Pagado',
                              '\$${_totalPaid.toStringAsFixed(0)}',
                              Colors.green,
                              Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              'Pendiente',
                              '\$${_totalPending.toStringAsFixed(0)}',
                              Colors.orange,
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
                  labelColor: const Color(0xFF003087),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF003087),
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Todos (${_allPayments.length})'),
                    Tab(text: 'Pagados (${_paidPayments.length})'),
                    Tab(text: 'Pendientes (${_pendingPayments.length})'),
                    Tab(text: 'Fallidos (${_failedPayments.length})'),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPayments,
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

  Widget _buildSummaryCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(List<Payment> payments) {
    if (payments.isEmpty) {
      return const Center(
        child: Text(
          'No hay pagos en esta categoría',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor,
                    child: Icon(
                      _getStatusIcon(payment.status),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${payment.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      payment.status.toUpperCase(),
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
                  Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(payment.method.toUpperCase()),
                  const SizedBox(width: 16),
                  if (payment.transactionId != null) ...[
                    Icon(Icons.receipt, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('ID: ${payment.transactionId!.substring(0, 8)}...'),
                  ],
                ],
              ),
              if (payment.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  payment.description!,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
              if (canRetry) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _retryPayment(payment),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar Pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003087),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}

class PaymentDetailsDialog extends StatelessWidget {
  final Payment payment;

  const PaymentDetailsDialog({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalles del Pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Monto', '\$${payment.amount.toStringAsFixed(0)}'),
          _buildDetailRow('Estado', payment.status.toUpperCase()),
          _buildDetailRow('Método', payment.method.toUpperCase()),
          if (payment.transactionId != null)
            _buildDetailRow('ID de Transacción', payment.transactionId!),
          _buildDetailRow(
            'Fecha de Creación',
            DateFormat('dd/MM/yyyy HH:mm').format(payment.createdAt),
          ),
          _buildDetailRow(
            'Última Actualización',
            DateFormat('dd/MM/yyyy HH:mm').format(payment.updatedAt),
          ),
          if (payment.description != null)
            _buildDetailRow('Descripción', payment.description!),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}