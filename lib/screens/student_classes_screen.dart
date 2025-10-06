import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/driving_class.dart';

const storage = FlutterSecureStorage();

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DrivingClass> _allClasses = [];
  List<DrivingClass> _scheduledClasses = [];
  List<DrivingClass> _completedClasses = [];
  List<DrivingClass> _canceledClasses = [];
  bool _isLoading = true;

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
        final classes = await ApiService.getDrivingClasses();
        
        _allClasses = classes
            .where((c) => c['studentId'].toString() == userId)
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

  Future<void> _cancelClass(DrivingClass drivingClass) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Clase'),
        content: const Text(
          '¿Estás seguro de que quieres cancelar esta clase?\n\n'
          'Nota: Las cancelaciones con menos de 24 horas de anticipación pueden tener penalizaciones.',
        ),
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
            const SnackBar(content: Text('Clase cancelada exitosamente')),
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

  Future<void> _rateClass(DrivingClass drivingClass) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => RateClassDialog(drivingClass: drivingClass),
    );

    if (result != null) {
      try {
        await ApiService.updateDrivingClass(
          drivingClass.id.toString(),
          {
            'rating': result['rating'],
            'feedback': result['feedback'],
          },
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calificación enviada exitosamente')),
          );
          _loadClasses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error enviando calificación: $e')),
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
    final canCancel = drivingClass.status == 'scheduled' && 
                     drivingClass.date.isAfter(DateTime.now().add(const Duration(hours: 1)));
    final canRate = drivingClass.status == 'completed' && drivingClass.rating == null;

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
                        'Instructor: ${drivingClass.instructor?['user']?['name'] ?? ''} ${drivingClass.instructor?['user']?['surname'] ?? ''}',
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas del instructor:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      drivingClass.notes!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            if (drivingClass.feedback != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mi comentario:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      drivingClass.feedback!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            if (canCancel || canRate) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canRate)
                    ElevatedButton.icon(
                      onPressed: () => _rateClass(drivingClass),
                      icon: const Icon(Icons.star),
                      label: const Text('Calificar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (canRate && canCancel) const SizedBox(width: 8),
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

class RateClassDialog extends StatefulWidget {
  final DrivingClass drivingClass;
  
  const RateClassDialog({super.key, required this.drivingClass});

  @override
  State<RateClassDialog> createState() => _RateClassDialogState();
}

class _RateClassDialogState extends State<RateClassDialog> {
  final _feedbackController = TextEditingController();
  double _rating = 5.0;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calificar Clase'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructor: ${widget.drivingClass.instructor?['user']?['name']} ${widget.drivingClass.instructor?['user']?['surname']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Tu calificación:'),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () => setState(() => _rating = index + 1.0),
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackController,
            decoration: const InputDecoration(
              labelText: 'Comentarios (opcional)',
              hintText: '¿Cómo fue tu experiencia?',
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
              'rating': _rating,
              'feedback': _feedbackController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
          ),
          child: const Text('Enviar'),
        ),
      ],
    );
  }
}