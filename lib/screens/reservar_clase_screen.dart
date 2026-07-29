import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:manejapp/models/instructor.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/screens/reservation_review_screen.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_empty_state.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/design/premium_async_states.dart';
import 'package:manejapp/widgets/design/app_avatar.dart';
import 'package:manejapp/utils/app_formatters.dart';

class ReservarClaseScreen extends StatefulWidget {
  static const routeName = '/reservar_clase';

  final Instructor? instructor;

  const ReservarClaseScreen({super.key, this.instructor});

  @override
  State<ReservarClaseScreen> createState() => _ReservarClaseScreenState();
}

class _ReservarClaseScreenState extends State<ReservarClaseScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<dynamic> _availableSlots = [];
  String? _selectedSlotId;
  Map<String, dynamic>? _selectedSlot;
  bool _isLoadingSlots = false;
  String? _slotsLoadError;

  List<dynamic> _allInstructorSlots = [];

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _loadAllSlots();
      _isInit = false;
    }
  }

  Future<void> _loadAllSlots() async {
    final instructor = _getInstructor();
    if (instructor == null) return;

    setState(() {
      _isLoadingSlots = true;
      _slotsLoadError = null;
    });

    try {
      final slots =
          await ApiService.getInstructorSchedule(instructor.id.toString());
      if (mounted) {
        setState(() {
          _allInstructorSlots = slots;
          _isLoadingSlots = false;
          _slotsLoadError = null;
          _updateAvailableSlotsForDay(_selectedDay!);
        });
      }
    } catch (e) {
      debugPrint('Error loading slots: $e');
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
          _slotsLoadError = humanizeApiError(e);
        });
      }
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _allInstructorSlots.where((slot) {
      final slotDate = DateTime.parse(slot['startTime']);
      final isAvailable = slot['isBooked'] != true;
      return isSameDay(slotDate, day) && isAvailable;
    }).toList();
  }

  void _updateAvailableSlotsForDay(DateTime day) {
    final daySlots = _getEventsForDay(day);
    daySlots.sort((a, b) => a['startTime'].compareTo(b['startTime']));
    setState(() {
      _availableSlots = daySlots;
      _selectedSlotId = null;
      _selectedSlot = null;
    });
  }

  Instructor? _getInstructor() {
    if (widget.instructor != null) return widget.instructor;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Instructor) return args;
    return null;
  }

  void _continueToReview() {
    if (_selectedSlotId == null || _selectedSlot == null) return;
    final instructor = _getInstructor();
    if (instructor == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationReviewScreen(
          instructor: instructor,
          slot: _selectedSlot!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final instructor = _getInstructor();
    if (instructor == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text('Reservar',
              style: AppTextStyles.heading.copyWith(fontSize: 20)),
        ),
        body: Center(
          child: AppEmptyState(
            icon: Icons.person_off_outlined,
            title: 'No encontramos al instructor',
            subtitle:
                'Volvé atrás y elegí un instructor de la lista o del mapa.',
          ),
        ),
      );
    }

    final startsAt = _selectedSlot == null
        ? null
        : DateTime.parse(_selectedSlot!['startTime'].toString());
    final endsAt = _selectedSlot == null
        ? null
        : DateTime.parse(_selectedSlot!['endTime'].toString());
    final duration = startsAt == null || endsAt == null
        ? null
        : endsAt.difference(startsAt).inMinutes;
    final estimatedPrice = duration == null
        ? null
        : ((instructor.effectiveHourlyRate / 60) * duration).round();
    final instructorName =
        '${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''}'
            .trim();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Reservar clase',
            style: AppTextStyles.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        AppAvatar(
                          diameter: 56,
                          name: instructorName.isEmpty
                              ? 'Instructor'
                              : instructorName,
                          imageUrl: instructor.user?.profileImageUrl ??
                              instructor.user?.profileImage,
                          showBorder: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                instructorName.isEmpty
                                    ? 'Instructor'
                                    : instructorName,
                                style: AppTextStyles.heading
                                    .copyWith(fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Desde ${AppFormatters.ars(instructor.effectiveHourlyRate)}/hora',
                                style: AppTextStyles.bodyNormal
                                    .copyWith(color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1) Elegí un día',
                            style:
                                AppTextStyles.heading.copyWith(fontSize: 16)),
                        const SizedBox(height: 10),
                        TableCalendar(
                          firstDay: DateTime.now(),
                          lastDay: DateTime.now().add(const Duration(days: 90)),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          eventLoader: _getEventsForDay,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                            _updateAvailableSlotsForDay(selectedDay);
                          },
                          calendarStyle: CalendarStyle(
                            defaultTextStyle:
                                const TextStyle(color: AppColors.textPrimary),
                            weekendTextStyle:
                                const TextStyle(color: AppColors.textSecondary),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            markersAlignment: Alignment.bottomCenter,
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, day, events) {
                              if (events.isEmpty) return null;
                              return Container(
                                margin: const EdgeInsets.only(top: 35),
                                width: 16,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              );
                            },
                          ),
                          headerStyle: HeaderStyle(
                            titleTextStyle:
                                AppTextStyles.heading.copyWith(fontSize: 16),
                            formatButtonVisible: false,
                            leftChevronIcon: const Icon(Icons.chevron_left,
                                color: AppColors.textPrimary),
                            rightChevronIcon: const Icon(Icons.chevron_right,
                                color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('2) Seleccioná horario',
                            style:
                                AppTextStyles.heading.copyWith(fontSize: 16)),
                        const SizedBox(height: 10),
                        if (_isLoadingSlots)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: SlotPickerSkeleton(),
                          )
                        else if (_slotsLoadError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: AppErrorState(
                              title: 'No pudimos cargar los horarios',
                              message: _slotsLoadError,
                              onRetry: _loadAllSlots,
                              retryLabel: 'Reintentar',
                            ),
                          )
                        else if (_availableSlots.isEmpty)
                          AppEmptyState(
                            icon: Icons.event_busy_rounded,
                            title: 'Sin turnos este día',
                            subtitle:
                                'Elegí otra fecha en el calendario o pedile al instructor que publique más disponibilidad.',
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _availableSlots.length,
                            itemBuilder: (context, index) {
                              final slot = _availableSlots[index];
                              final isSelected =
                                  _selectedSlotId == slot['id'].toString();
                              final start = DateTime.parse(slot['startTime']);
                              final timeLabel =
                                  DateFormat('HH:mm').format(start);
                              return Semantics(
                                button: true,
                                selected: isSelected,
                                label: 'Horario $timeLabel',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selectedSlotId = slot['id'].toString();
                                        _selectedSlot =
                                            Map<String, dynamic>.from(
                                                slot as Map);
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: AppMotion.duration(
                                          context, AppDurations.fast),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.surfaceLighter,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        timeLabel,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.textInverse
                                              : AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  if (_selectedSlot != null) ...[
                    const SizedBox(height: 14),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('3) Revisión previa',
                              style:
                                  AppTextStyles.heading.copyWith(fontSize: 16)),
                          const SizedBox(height: 10),
                          _line('Horario',
                              '${DateFormat('HH:mm').format(startsAt!)} - ${DateFormat('HH:mm').format(endsAt!)}'),
                          _line('Duración', '${duration ?? 0} min'),
                          _line(
                              'Precio estimado',
                              estimatedPrice == null
                                  ? '—'
                                  : AppFormatters.ars(estimatedPrice)),
                          const SizedBox(height: 8),
                          Text(
                            'Vas a revisar y confirmar todo antes de reservar.',
                            style: AppTextStyles.bodyNormal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: AppButton(
              text: 'Continuar al review premium',
              onPressed: _selectedSlotId == null ? null : _continueToReview,
              type: _selectedSlotId == null
                  ? AppButtonType.secondary
                  : AppButtonType.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyNormal),
          Text(value,
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
