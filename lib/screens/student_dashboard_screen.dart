import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/driving_class.dart';
import '../models/payment.dart';
import 'student_classes_screen.dart';
import 'student_payments_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

const storage = FlutterSecureStorage();

class StudentDashboardScreen extends StatefulWidget {
  static const routeName = '/student_dashboard';
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _selectedIndex = 0;

  List<DrivingClass> _upcomingClasses = [];
  List<Payment> _recentPayments = [];
  bool _isLoading = true;
  String _studentName = '';
  int _totalClasses = 0;
  int _completedClasses = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _loadDashboardData() async {
    try {
      final userId = await storage.read(key: 'user_id');
      if (userId != null) {
        // Obtener información del usuario
        final user = await ApiService.getUserProfile(userId);
        _studentName = '${user['name'] ?? ''} ${user['surname'] ?? ''}'.trim();
        
        // Obtener el studentId del usuario
        String? studentId;
        try {
          final students = await ApiService.getUsersByRole('STUDENT');
          final student = students.firstWhere(
            (s) => s['userId'].toString() == userId,
            orElse: () => null,
          );
          studentId = student?['id']?.toString();
        } catch (e) {
          debugPrint('Error obteniendo studentId: $e');
        }
        
        // Cargar clases del estudiante
        final classes = await ApiService.getDrivingClasses();
        final studentClasses = classes
            .where((c) => studentId != null && c['studentId'].toString() == studentId)
            .map((c) => DrivingClass.fromJson(c))
            .toList();

        _totalClasses = studentClasses.length;
        _completedClasses = studentClasses.where((c) => c.status == 'completed').length;
        
        // Próximas clases (programadas y futuras)
        final now = DateTime.now();
        _upcomingClasses = studentClasses
            .where((c) => 
              c.status == 'scheduled' && 
              c.date.isAfter(now.subtract(const Duration(hours: 1))))
            .toList();
        _upcomingClasses.sort((a, b) => a.date.compareTo(b.date));

        // Cargar pagos recientes
        final payments = await ApiService.getPayments();
        _recentPayments = payments
            .map((p) => Payment.fromJson(p))
            .where((p) => studentClasses.any((c) => c.id == p.drivingClassId))
            .toList();
        _recentPayments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('Error cargando dashboard: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, $_studentName'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Mis Clases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'Pagos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF003087),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }



  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const HomeScreen();
      case 2:
        return const StudentClassesScreen();
      case 3:
        return const StudentPaymentsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estadísticas generales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mi Progreso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total de Clases',
                            _totalClasses.toString(),
                            Icons.school,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Completadas',
                            _completedClasses.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Próximas',
                            _upcomingClasses.length.toString(),
                            Icons.schedule,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Progreso',
                            _totalClasses > 0 
                                ? '${((_completedClasses / _totalClasses) * 100).round()}%'
                                : '0%',
                            Icons.trending_up,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Próximas clases
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Próximas Clases',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedIndex = 2),
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_upcomingClasses.isEmpty)
                      const Text(
                        'No tienes clases programadas.\n¡Busca un instructor y agenda tu próxima clase!',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ..._upcomingClasses.take(3).map((drivingClass) => 
                        _buildUpcomingClassCard(drivingClass)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pagos recientes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pagos Recientes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedIndex = 3),
                          child: const Text('Ver todos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_recentPayments.isEmpty)
                      const Text(
                        'No tienes pagos registrados',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ..._recentPayments.take(3).map((payment) => 
                        _buildPaymentCard(payment)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Acciones rápidas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _selectedIndex = 1),
                            icon: const Icon(Icons.search),
                            label: const Text('Buscar Instructor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003087),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _selectedIndex = 4),
                            icon: const Icon(Icons.person),
                            label: const Text('Mi Perfil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
            value,
            style: TextStyle(
              fontSize: 24,
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

  Widget _buildUpcomingClassCard(DrivingClass drivingClass) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: const Icon(Icons.schedule, color: Colors.white),
        ),
        title: Text(
          '${drivingClass.instructor?['user']?['name'] ?? ''} ${drivingClass.instructor?['user']?['surname'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('EEEE, d MMMM').format(drivingClass.date)),
            Text('${drivingClass.time} - ${drivingClass.duration} min'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => setState(() => _selectedIndex = 2),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final statusColor = _getPaymentStatusColor(payment.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            _getPaymentStatusIcon(payment.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          '\$${payment.amount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payment.method.toUpperCase()),
            Text(DateFormat('dd/MM/yyyy').format(payment.createdAt)),
          ],
        ),
        trailing: Container(
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
      ),
    );
  }

  Color _getPaymentStatusColor(String status) {
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

  IconData _getPaymentStatusIcon(String status) {
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