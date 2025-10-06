import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/driving_class.dart';

const storage = FlutterSecureStorage();

class InstructorClassesScreen extends StatefulWidget {
  const InstructorClassesScreen({super.key});

  @override
  State<InstructorClassesScreen> createState() => _InstructorClassesScreenState();
}

class _InstructorClassesScreenState extends State<InstructorClassesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DrivingClass> _allClasses = [];
  List<DrivingClass> _scheduledClasses = [];
  List<DrivingClass> _completedClasses = [];
  List<DrivingClass> _canceledClasses = [];
  bool _isLoading = true;
  String? _instructorId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final userId = await storage.read(key: 'user_id');
      if (userId != null) {
        // Obtener ID del instructor
        final instructors = await ApiService.getInstructors();
        final instructor = instructors.firstWhere(
          (i) => i['userId'].toString() == userId,
          orElse: () => null,
        );
        
        if (instructor != null) {
          _instructorId = instructor['id'].toString();
          final classes = await ApiService.getDrivingClasses();
          
          _allClasses = classes
              .where((c) => c['instructorId'].toString() == _instructorId)
              .map((c) => DrivingClass.fromJson(c))
              .toList();

          // Filtrar por estado
          _scheduledClasses = _allClasses.where((c) => c.status == 'scheduled').toList();
          _completedClasses = _allClasses.where((c) => c.status == 'completed').toList();
          _canceledClasses = _allClasses.where((c) => c.status == 'canceled').toList();

          // Ordenar por fecha
          _allClasses.sort((a, b) => b.date.compareTo(a.date));
          _scheduledClasses.sort((a, b) => a.date.compareTo(b.date));
          _completedClasses.sort((a, b) => b.date.compareTo(a.date));
          _canceledClasses.sort((a, b) => b.date.compareTo(a.date));
        }
      }
    } catch (e) {
      debugPrint('Error cargando clases: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando clases: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _completeClass(DrivingClass drivingClass) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CompleteClassDialog(drivingClass: drivingClass),
    );

    if (result != null) {
      try {
        await ApiService.updateDrivingClass(
          drivingClass.id.toString(),
          {
            'status': 'completed',
            'notes': result['notes'],
            'rating': result['rating'],
          },
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clase completada exitosamente')),
          );
          _loadClasses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error completando clase: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelClass(DrivingClass drivingClass) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Clase'),
        content: const Text('¿Estás seguro de que quieres cancelar esta clase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.cancelDrivingClass(drivingClass.id.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clase cancelada')),
          );
          _loadClasses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelando clase: $e')),
          );
        }
      }
    }
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
                    'Mis Clases',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF003087),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF003087),
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Todas (${_allClasses.length})'),
                    Tab(text: 'Programadas (${_scheduledClasses.length})'),
                    Tab(text: 'Completadas (${_completedClasses.length})'),
                    Tab(text: 'Canceladas (${_canceledClasses.length})'),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadClasses,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildClassesList(_allClasses),
                        _buildClassesList(_scheduledClasses),
                        _buildClassesList(_completedClasses),
                        _buildClassesList(_canceledClasses),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildClassesList(List<DrivingClass> classes) {
    if (classes.isEmpty) {
      return const Center(
        child: Text(
          'No hay clases en esta categoría',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final drivingClass = classes[index];
        return _buildClassCard(drivingClass);
      },
    );
  }

  Widget _buildClassCard(DrivingClass drivingClass) {
    final statusColor = _getStatusColor(drivingClass.status);
    final canComplete = drivingClass.status == 'scheduled' && 
                       drivingClass.date.isBefore(DateTime.now().add(const Duration(hours: 1)));
    final canCancel = drivingClass.status == 'scheduled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    _getStatusIcon(drivingClass.status),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${drivingClass.student?.name ?? ''} ${drivingClass.student?.surname ?? ''}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'es').format(drivingClass.date),
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
                    drivingClass.status.toUpperCase(),
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
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${drivingClass.time} (${drivingClass.duration} min)'),
                const SizedBox(width: 16),
                if (drivingClass.rating != null) ...[
                  Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                  const SizedBox(width: 4),
                  Text('${drivingClass.rating}/5'),
                ],
              ],
            ),
            if (drivingClass.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                'Notas: ${drivingClass.notes}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            if (canComplete || canCancel) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canComplete)
                    ElevatedButton.icon(
                      onPressed: () => _completeClass(drivingClass),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Completar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (canComplete && canCancel) const SizedBox(width: 8),
                  if (canCancel)
                    OutlinedButton.icon(
                      onPressed: () => _cancelClass(drivingClass),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ],
          ],
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

class CompleteClassDialog extends StatefulWidget {
  final DrivingClass drivingClass;
  
  const CompleteClassDialog({super.key, required this.drivingClass});

  @override
  State<CompleteClassDialog> createState() => _CompleteClassDialogState();
}

class _CompleteClassDialogState extends State<CompleteClassDialog> {
  final _notesController = TextEditingController();
  double _rating = 5.0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Completar Clase'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estudiante: ${widget.drivingClass.student?.name} ${widget.drivingClass.student?.surname}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Calificación del estudiante:'),
          Slider(
            value: _rating,
            min: 1,
            max: 5,
            divisions: 4,
            label: _rating.toString(),
            onChanged: (value) => setState(() => _rating = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notas de la clase',
              hintText: 'Progreso, áreas de mejora, etc.',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'notes': _notesController.text,
              'rating': _rating,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Completar'),
        ),
      ],
    );
  }
}