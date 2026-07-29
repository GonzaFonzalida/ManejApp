import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/services/api_service.dart';
import 'package:manejapp/utils/app_feedback.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';

/// Pantalla para reprogramar una clase confirmada a otro horario disponible
/// del mismo instructor y de igual duración. Devuelve `true` al hacer pop si
/// la reprogramación fue exitosa.
class RescheduleClassScreen extends StatefulWidget {
  final int bookingId;
  final int instructorId;
  final int durationMinutes;

  const RescheduleClassScreen({
    super.key,
    required this.bookingId,
    required this.instructorId,
    required this.durationMinutes,
  });

  @override
  State<RescheduleClassScreen> createState() => _RescheduleClassScreenState();
}

class _SlotOption {
  final String id;
  final DateTime start;
  final DateTime end;

  _SlotOption({required this.id, required this.start, required this.end});

  int get durationMinutes => end.difference(start).inMinutes;
}

class _RescheduleClassScreenState extends State<RescheduleClassScreen> {
  bool _loading = true;
  String? _loadError;
  bool _submitting = false;
  String? _selectedSlotId;
  List<_SlotOption> _slots = [];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final raw = await ApiService.getInstructorSchedule(
          widget.instructorId.toString());
      final now = DateTime.now();
      final options = <_SlotOption>[];
      for (final item in raw) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final status = (map['status'] ?? '').toString();
        if (status.isNotEmpty && status != 'AVAILABLE') continue;
        final start = DateTime.tryParse(map['startTime']?.toString() ?? '');
        final end = DateTime.tryParse(map['endTime']?.toString() ?? '');
        final id = map['id']?.toString();
        if (start == null || end == null || id == null) continue;
        if (!start.isAfter(now)) continue;
        final option = _SlotOption(id: id, start: start, end: end);
        // Misma duración que la clase original (el monto ya pagado no cambia).
        if (option.durationMinutes != widget.durationMinutes) continue;
        options.add(option);
      }
      options.sort((a, b) => a.start.compareTo(b.start));
      if (!mounted) return;
      setState(() {
        _slots = options;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final slotId = _selectedSlotId;
    if (slotId == null) return;

    setState(() => _submitting = true);
    try {
      await ApiService.rescheduleReservation(
        widget.bookingId.toString(),
        slotId,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Clase reprogramada correctamente.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, humanizeApiError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Reprogramar clase',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AppErrorState(
            title: 'No pudimos cargar los horarios',
            message: _loadError,
            onRetry: _loadSlots,
            retryLabel: 'Reintentar',
          ),
        ),
      );
    }

    if (_slots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_outlined,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Sin horarios disponibles',
                style: AppTextStyles.heading.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Este instructor no tiene horarios libres de ${widget.durationMinutes} min por ahora. '
                'Probá más tarde.',
                style: AppTextStyles.bodyNormal
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            itemCount: _slots.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final slot = _slots[index];
              final selected = slot.id == _selectedSlotId;
              return InkWell(
                onTap: () => setState(() => _selectedSlotId = slot.id),
                borderRadius: BorderRadius.circular(16),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              toBeginningOfSentenceCase(
                                    DateFormat('EEEE d MMMM', 'es')
                                        .format(slot.start),
                                  ) ??
                                  DateFormat('EEEE d MMMM', 'es')
                                      .format(slot.start),
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('HH:mm').format(slot.start)} - ${DateFormat('HH:mm').format(slot.end)}'
                              ' · ${slot.durationMinutes} min',
                              style: AppTextStyles.bodyNormal
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: AppButton(
            text: 'Confirmar reprogramación',
            onPressed: _submitting || _selectedSlotId == null ? null : _confirm,
            isLoading: _submitting,
            type: AppButtonType.primary,
          ),
        ),
      ],
    );
  }
}
