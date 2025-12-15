import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'admin_users_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_logs_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const routeName = '/admin_dashboard';
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('AdminDashboard initState called');
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('=== LOADING STATS ===');
      
      debugPrint('Fetching students...');
      final students = await ApiService.getUsersByRole('STUDENT');
      debugPrint('Students count: ${students.length}');
      
      debugPrint('Fetching instructors...');
      final instructors = await ApiService.getUsersByRole('INSTRUCTOR');
      debugPrint('Instructors count: ${instructors.length}');
      
      debugPrint('Fetching classes...');
      final classes = await ApiService.getDrivingClasses();
      debugPrint('Classes count: ${classes.length}');
      
      if (mounted) {
        setState(() {
          _stats = {
            'totalStudents': students.length,
            'totalInstructors': instructors.length,
            'totalClasses': classes.length,
            'completedClasses': classes.where((c) => c['status'] == 'completed').length,
            'totalRevenue': 0,
            'pendingPayments': 0,
          };
          _isLoading = false;
        });
        debugPrint('Stats updated: $_stats');
      }
    } catch (e, stackTrace) {
      debugPrint('=== ERROR LOADING STATS ===');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _stats = {
            'totalStudents': 0,
            'totalInstructors': 0,
            'totalClasses': 0,
            'completedClasses': 0,
            'totalRevenue': 0,
            'pendingPayments': 0,
          };
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF003087),
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildDashboard();
      case 1: return const AdminUsersScreen();
      case 2: return const AdminReportsScreen();
      case 3: return const AdminLogsScreen();
      case 4: return const AdminSettingsScreen();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    print('Building dashboard with stats: $_stats');
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumen General', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.8,
              children: [
                _buildStatCard('Estudiantes', '${_stats['totalStudents'] ?? 0}', Icons.school, Colors.blue),
                _buildStatCard('Instructores', '${_stats['totalInstructors'] ?? 0}', Icons.person, Colors.green),
                _buildStatCard('Clases Totales', '${_stats['totalClasses'] ?? 0}', Icons.class_, Colors.orange),
                _buildStatCard('Completadas', '${_stats['completedClasses'] ?? 0}', Icons.check_circle, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ingresos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRevenueCard('Total Recaudado', '\$${(_stats['totalRevenue'] ?? 0).toStringAsFixed(0)}', Colors.green),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildRevenueCard('Pagos Pendientes', (_stats['pendingPayments'] ?? 0).toString(), Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Acciones Rápidas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 1),
                    icon: const Icon(Icons.people),
                    label: const Text('Gestionar Usuarios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003087),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _selectedIndex = 2),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Ver Reportes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
