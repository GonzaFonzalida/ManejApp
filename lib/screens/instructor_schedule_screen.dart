import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/schedule_slot.dart';

const storage = FlutterSecureStorage();

class InstructorScheduleScreen extends StatefulWidget {
  const InstructorScheduleScreen({super.key});

  @override
  State<InstructorScheduleScreen> createState() => _InstructorScheduleScreenState();
}

class _InstructorScheduleScreenState extends State<InstructorScheduleScreen> {
  List<ScheduleSlot> _scheduleSlots = [];
  bool _isLoading = true;
  String? _instructorId;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
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
          final slots = await ApiService.getInstructorSchedule(_instructorId!);
          _scheduleSlots = slots.map((s) => ScheduleSlot.fromJson(s)).toList();
          
          // Ordenar por fecha y hora
          _scheduleSlots.sort((a, b) {
            final dateComparison = a.date.compareTo(b.date);
            if (dateComparison != 0) return dateComparison;
            return a.startTime.compareTo(b.startTime);
          });
        }
      }
    } catch (e) {
      debugPrint('Error cargando horarios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando horarios: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createScheduleSlot() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateScheduleSlotDialog(),
    );

    if (result != null && _instructorId != null) {
      try {
        await ApiService.createScheduleSlot({
          'instructorId': int.parse(_instructorId!),
          ...result,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Horario creado exitosamente')),
          );
          _loadSchedule();
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Error creando horario: $e';
          if (e.toString().contains('superpone')) {
            errorMessage = 'Ya tienes un horario en ese rango de tiempo. Elige otro horario.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    }
  }

  Future<void> _editHourlyRate() async {
    final currentRate = await _getCurrentHourlyRate();
    final controller = TextEditingController(text: currentRate.toString());
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Precio por Hora'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Precio por hora',
            prefixText: '\$ ',
            suffixText: '/h',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      try {
        final userId = await storage.read(key: 'user_id');
        if (userId != null) {
          await ApiService.updateProfile(userId, {
            'hourlyRate': int.tryParse(result) ?? 0,
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Precio actualizado exitosamente')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error actualizando precio: $e')),
          );
        }
      }
    }
  }
  
  Future<int> _getCurrentHourlyRate() async {
    try {
      final userId = await storage.read(key: 'user_id');
      if (userId != null) {
        final profile = await ApiService.getUserProfile(userId);
        return profile['hourlyRate'] ?? 45000;
      }
    } catch (e) {
      debugPrint('Error obteniendo precio: $e');
    }
    return 45000;
  }

  Future<void> _deleteScheduleSlot(ScheduleSlot slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar este horario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteScheduleSlot(slot.id.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Horario eliminado')),
          );
          _loadSchedule();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error eliminando horario: $e')),
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
          : RefreshIndicator(
              onRefresh: _loadSchedule,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Mis Horarios',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _editHourlyRate,
                              icon: const Icon(Icons.attach_money),
                              tooltip: 'Editar precio por hora',
                            ),
                            ElevatedButton.icon(
                              onPressed: _createScheduleSlot,
                              icon: const Icon(Icons.add),
                              label: const Text('Crear Horario'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003087),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _scheduleSlots.isEmpty
                        ? const Center(
                            child: Text(
                              'No tienes horarios creados.\nToca "Crear Horario" para empezar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _scheduleSlots.length,
                            itemBuilder: (context, index) {
                              final slot = _scheduleSlots[index];
                              return _buildScheduleSlotCard(slot);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildScheduleSlotCard(ScheduleSlot slot) {
    final isAvailable = slot.isAvailable;
    final isPast = slot.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPast
              ? Colors.grey
              : isAvailable
                  ? Colors.green
                  : Colors.orange,
          child: Icon(
            isPast
                ? Icons.history
                : isAvailable
                    ? Icons.schedule
                    : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          DateFormat('EEEE, d MMMM yyyy').format(slot.date),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${slot.startTime} - ${slot.endTime}'),
            if (!isAvailable && slot.student != null)
              Text(
                'Reservado por: ${slot.student!.name} ${slot.student!.surname}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'delete':
                _deleteScheduleSlot(slot);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateScheduleSlotDialog extends StatefulWidget {
  const CreateScheduleSlotDialog({super.key});

  @override
  State<CreateScheduleSlotDialog> createState() => _CreateScheduleSlotDialogState();
}

class _CreateScheduleSlotDialogState extends State<CreateScheduleSlotDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Nuevo Horario'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Fecha'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            ListTile(
              title: const Text('Hora de inicio'),
              subtitle: Text(_startTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                );
                if (time != null) {
                  setState(() => _startTime = time);
                }
              },
            ),
            ListTile(
              title: const Text('Hora de fin'),
              subtitle: Text(_endTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                );
                if (time != null) {
                  setState(() => _endTime = time);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Validar que la hora de fin sea posterior a la de inicio
              final startMinutes = _startTime.hour * 60 + _startTime.minute;
              final endMinutes = _endTime.hour * 60 + _endTime.minute;
              
              if (endMinutes <= startMinutes) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La hora de fin debe ser posterior a la de inicio')),
                );
                return;
              }
              
              // Validar duración máxima (4 horas)
              final durationMinutes = endMinutes - startMinutes;
              if (durationMinutes > 240) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La duración máxima es de 4 horas')),
                );
                return;
              }
              
              final startDateTime = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _startTime.hour,
                _startTime.minute,
              );
              final endDateTime = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _endTime.hour,
                _endTime.minute,
              );
              
              Navigator.pop(context, {
                'date': _selectedDate.toIso8601String().split('T')[0],
                'startTime': startDateTime.toUtc().toIso8601String(),
                'endTime': endDateTime.toUtc().toIso8601String(),
                'isAvailable': true,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF003087),
            foregroundColor: Colors.white,
          ),
          child: const Text('Crear'),
        ),
      ],
    );
  }
}