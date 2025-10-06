import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/driving_class.dart';
import '../models/schedule_slot.dart';
import 'instructor_schedule_screen.dart';
import 'instructor_classes_screen.dart';
import 'instructor_profile_screen.dart';

const storage = FlutterSecureStorage();

class InstructorDashboardScreen extends StatefulWidget {
  static const routeName = '/instructor_dashboard';
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() => _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  int _selectedIndex = 0;
  List<DrivingClass> _todayClasses = [];
  List<ScheduleSlot> _availableSlots = [];
  bool _isLoading = true;
  String _instructorName = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    debugPrint('=== INICIANDO _loadDashboardData ===');
    try {
      final userId = await storage.read(key: 'user_id');
      debugPrint('UserId obtenido: $userId');
      
      if (userId != null) {
        // Obtener información del instructor
        debugPrint('Obteniendo instructores...');
        final instructors = await ApiService.getInstructors();
        debugPrint('Instructores obtenidos: ${instructors.length}');
        
        final instructor = instructors.firstWhere(
          (i) => i['userId'].toString() == userId,
          orElse: () => null,
        );
        
        if (instructor != null) {
          final instructorId = instructor['id'].toString();
          debugPrint('InstructorId encontrado: $instructorId');
          
          // Cargar clases de hoy
          debugPrint('Cargando clases...');
          final classes = await ApiService.getDrivingClasses();
          final today = DateTime.now();
          _todayClasses = classes
              .where((c) => 
                c['instructorId'].toString() == instructorId &&
                DateTime.parse(c['date']).day == today.day)
              .map((c) => DrivingClass.fromJson(c))
              .toList();
          debugPrint('Clases de hoy: ${_todayClasses.length}');

          // Cargar horarios disponibles
          debugPrint('Cargando horarios del instructor...');
          final slots = await ApiService.getInstructorSchedule(instructorId);
          debugPrint('Total slots obtenidos: ${slots.length}');
          
          for (var slot in slots) {
            debugPrint('Slot: ${slot['id']}, isBooked: ${slot['isBooked']}');
          }
          
          _availableSlots = slots
              .where((s) => s['isBooked'] != true)
              .map((s) => ScheduleSlot.fromJson(s))
              .toList();
              
          debugPrint('Horarios disponibles filtrados: ${_availableSlots.length}');

          _instructorName = instructor['user']?['name'] ?? 'Instructor';
          debugPrint('Nombre instructor: $_instructorName');
        } else {
          debugPrint('ERROR: Instructor no encontrado para userId: $userId');
        }
      } else {
        debugPrint('ERROR: UserId es null');
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR cargando dashboard: $e');
      debugPrint('StackTrace: $stackTrace');
    } finally {
      debugPrint('=== FINALIZANDO _loadDashboardData ===');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - $_instructorName'),
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
            icon: Icon(Icons.schedule),
            label: 'Horarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Clases',
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
        return const InstructorScheduleScreen();
      case 2:
        return const InstructorClassesScreen();
      case 3:
        return const InstructorProfileScreen();
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
            // Resumen del día
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen de Hoy',
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
                            'Clases Programadas',
                            _todayClasses.length.toString(),
                            Icons.school,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Horarios Disponibles',
                            _availableSlots.length.toString(),
                            Icons.schedule,
                            Colors.green,
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
                    const Text(
                      'Próximas Clases',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_todayClasses.isEmpty)
                      const Text(
                        'No tienes clases programadas para hoy',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ..._todayClasses.take(3).map((drivingClass) => 
                        _buildClassCard(drivingClass)),
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
                            icon: const Icon(Icons.add_alarm),
                            label: const Text('Crear Horario'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003087),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _selectedIndex = 3),
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar Perfil'),
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

  Widget _buildClassCard(DrivingClass drivingClass) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(drivingClass.status),
          child: Icon(
            _getStatusIcon(drivingClass.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          '${drivingClass.student?.name ?? ''} ${drivingClass.student?.surname ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${drivingClass.time} - ${drivingClass.duration} min'),
        trailing: Text(
          drivingClass.status.toUpperCase(),
          style: TextStyle(
            color: _getStatusColor(drivingClass.status),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}