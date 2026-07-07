import 'package:flutter/material.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_empty_state.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/premium_async_states.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/widgets/skeleton_loader.dart';
import 'package:intl/intl.dart';

const storage = appSecureStorage;

class InstructorScheduleScreen extends StatefulWidget {
  static const routeName = '/instructor_schedule';
  const InstructorScheduleScreen({super.key});

  @override
  State<InstructorScheduleScreen> createState() => _InstructorScheduleScreenState();
}

class _InstructorScheduleScreenState extends State<InstructorScheduleScreen> {
  List<dynamic> _scheduleSlots = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final userId = await storage.read(key: 'user_id');
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadError = 'No encontramos tu sesión. Volvé a iniciar sesión.';
          });
        }
        return;
      }

      final instructors = await ApiService.getInstructors();
      Map<String, dynamic>? meInstructor;
      for (final raw in instructors) {
        if (raw is! Map) continue;
        final i = Map<String, dynamic>.from(raw);
        if (i['userId'].toString() == userId) {
          meInstructor = i;
          break;
        }
      }

      if (meInstructor != null) {
        final fetchedSlots =
            await ApiService.getInstructorSchedule(meInstructor['id'].toString());
        fetchedSlots.sort((a, b) {
          final startA = a['startTime'] as String;
          final startB = b['startTime'] as String;
          return startA.compareTo(startB);
        });

        if (mounted) {
          setState(() {
            _scheduleSlots = fetchedSlots;
            _isLoading = false;
            _loadError = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _scheduleSlots = [];
            _isLoading = false;
            _loadError = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = humanizeApiError(e);
        });
      }
    }
  }

  String _toIso8601UTC(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final s = utc.second.toString().padLeft(2, '0');
    return "$y-$m-${d}T$h:$min:${s}Z";
  }

  Future<void> _createSlot() async {
      // Simple Time Picker and Date Picker
      final now = DateTime.now();
      final date = await showDatePicker(
          context: context, 
          initialDate: now, 
          firstDate: now, 
          lastDate: now.add(const Duration(days: 90)),
          builder: (context, child) {
              return Theme(
                  data: AppTheme.darkTheme.copyWith( // Corrected from DesignSystem.darkTheme
                      colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          onPrimary: AppColors.textInverse,
                          surface: AppColors.surfaceLight,
                      ),
                  ),
                  child: child!,
              );
          }
      );
      
      if (date == null) return;
      
      final time = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 9, minute: 0),
          builder: (context, child) {
               return Theme(
                  data: AppTheme.darkTheme.copyWith( // Corrected from DesignSystem.darkTheme
                      colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          onPrimary: AppColors.textInverse,
                          surface: AppColors.surfaceLight,
                      ),
                  ),
                  child: child!,
              );
          }
      );
      
      if (time == null) return;
      
      // Create slot logic (API call)
      try {
          final startDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          final endDateTime = startDateTime.add(const Duration(minutes: 60));

          debugPrint('Creating slot with start: ${_toIso8601UTC(startDateTime)}');

          await ApiService.createScheduleSlot({
              'startTime': _toIso8601UTC(startDateTime),
              'endTime': _toIso8601UTC(endDateTime),
          });
          
          _loadSchedule();
          AppFeedback.showSuccess(context, 'Horario creado exitosamente');
      } catch (e) {
          AppFeedback.showError(context, humanizeApiError(e));
      }
  }

  Future<void> _deleteSlot(String slotId) async {
       try {
           await ApiService.deleteScheduleSlot(slotId);
           _loadSchedule();
           AppFeedback.showSuccess(context, 'Horario eliminado');
       } catch (e) {
           AppFeedback.showError(context, humanizeApiError(e));
       }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonLoader(
                        width: 160,
                        height: 26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SkeletonLoader(
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.all(Radius.circular(22)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Expanded(
                    child: SingleChildScrollView(
                      child: InstructorScheduleSkeleton(),
                    ),
                  ),
                ],
              ),
            )
          : _loadError != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: AppErrorState(
                      title: 'No pudimos cargar tu agenda',
                      message: _loadError,
                      onRetry: _loadSchedule,
                      retryLabel: 'Reintentar',
                    ),
                  ),
                )
              : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Text('Mis Horarios', style: AppTextStyles.heading),
                              IconButton(
                                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                                  onPressed: _loadSchedule,
                              )
                          ],
                      ),
                      const SizedBox(height: 20),
                      
                      if (_scheduleSlots.isEmpty)
                          Expanded(
                              child: Center(
                                  child: AppEmptyState(
                                    icon: Icons.event_available_outlined,
                                    title: 'Todavía no publicaste horarios',
                                    subtitle:
                                        'Cargá tus horarios disponibles para que los alumnos puedan reservarte.',
                                    actionLabel: 'Crear horario',
                                    onAction: _createSlot,
                                  ),
                              ),
                          )
                      else
                          Expanded(
                              child: ListView.builder(
                                  itemCount: _scheduleSlots.length,
                                  itemBuilder: (context, index) {
                                      final slot = _scheduleSlots[index];
                                      // Use startTime for date parsing
                                      final date = DateTime.parse(slot['startTime']);
                                      final isBooked = slot['isBooked'] == true;
                                      
                                      return Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: AppCard(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                  children: [
                                                      Container(
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(
                                                              color: isBooked ? AppColors.success.withOpacity(0.1) : AppColors.surfaceLighter,
                                                              borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Icon(
                                                              Icons.access_time,
                                                              color: isBooked ? AppColors.success : AppColors.textPrimary,
                                                          ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                          child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                  Text(
                                                                      DateFormat('EEEE d MMM', 'es').format(date).toUpperCase(),
                                                                      style: AppTextStyles.bodyNormal.copyWith(fontSize: 12, color: AppColors.textSecondary),
                                                                  ),
                                                                  Text(
                                                                      DateFormat('HH:mm').format(date),
                                                                      style: AppTextStyles.heading.copyWith(fontSize: 20),
                                                                  ),
                                                                  if (isBooked)
                                                                      Text('RESERVADO', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                                                              ],
                                                          ),
                                                      ),
                                                      if (!isBooked)
                                                          IconButton(
                                                              icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                                              onPressed: () => _deleteSlot(slot['id'].toString()),
                                                          ),
                                                  ],
                                              ),
                                          ),
                                      );
                                  },
                              ),
                          ),
                  ],
              ),
          ),
      floatingActionButton: FloatingActionButton(
          onPressed: _createSlot,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.textInverse),
      ),
    );
  }
}
