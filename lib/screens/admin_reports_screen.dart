// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import '../services/api_service.dart';

@Deprecated('V1: usar panel web.')
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _reportData = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final classes = await ApiService.getDrivingClasses();
      final payments = await ApiService.getPayments();

      final now = DateTime.now();
      final thisMonth = classes.where((c) {
        final date = DateTime.parse(c['date']);
        return date.month == now.month && date.year == now.year;
      }).length;

      final lastMonth = classes.where((c) {
        final date = DateTime.parse(c['date']);
        final lastMonthDate = DateTime(now.year, now.month - 1);
        return date.month == lastMonthDate.month &&
            date.year == lastMonthDate.year;
      }).length;

      final monthlyRevenue = payments.where((p) {
        final date = DateTime.parse(p['createdAt']);
        return p['status'] == 'paid' &&
            date.month == now.month &&
            date.year == now.year;
      }).fold(0.0, (sum, p) => sum + (p['amount'] ?? 0));

      setState(() {
        _reportData = {
          'classesThisMonth': thisMonth,
          'classesLastMonth': lastMonth,
          'monthlyRevenue': monthlyRevenue,
          'totalClasses': classes.length,
          'completedClasses':
              classes.where((c) => c['status'] == 'completed').length,
          'canceledClasses':
              classes.where((c) => c['status'] == 'canceled').length,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading reports: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadReports,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reportes y Estadísticas',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Clases por Mes',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  'Este Mes',
                                  _reportData['classesThisMonth'].toString(),
                                  Colors.blue,
                                  Icons.calendar_today,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMetricCard(
                                  'Mes Anterior',
                                  _reportData['classesLastMonth'].toString(),
                                  Colors.grey,
                                  Icons.calendar_month,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingresos del Mes',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              '\$${_reportData['monthlyRevenue'].toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Exportación de reportes próximamente')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar Reporte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003087),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildMetricCard(
      String title, String value, Color color, IconData icon) {
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
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
