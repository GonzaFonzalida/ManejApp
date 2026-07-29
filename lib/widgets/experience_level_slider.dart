import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manejapp/config/design_system.dart';

const Duration _kMotionDuration = Duration(milliseconds: 240);
const Duration _kLabelSwitchDuration = Duration(milliseconds: 220);
const Curve _kMotionCurve = Curves.easeOutCubic;

/// Selector discreto de 5 niveles (sin slider). API estable para registro de alumno.
class ExperienceLevelSlider extends StatefulWidget {
  const ExperienceLevelSlider({
    super.key,
    required this.level,
    required this.onLevelChanged,

    /// Cuando true, los segmentos no seleccionados contrastan sobre panel [AppColors.surfaceLight].
    this.embeddedOnPanel = false,
  }) : assert(level >= 1 && level <= 5);

  final int level;
  final ValueChanged<int> onLevelChanged;
  final bool embeddedOnPanel;

  static const List<String> levelLabels = [
    'Estoy en 0 😅',
    'Recién arranco 🙌',
    'Algo sé 😌',
    'Me tengo fe 😎',
    'Quiero pulir detalles 🚀',
  ];

  @override
  State<ExperienceLevelSlider> createState() => _ExperienceLevelSliderState();
}

class _ExperienceLevelSliderState extends State<ExperienceLevelSlider> {
  late int _lastEmittedLevel;

  @override
  void initState() {
    super.initState();
    _lastEmittedLevel = widget.level;
  }

  @override
  void didUpdateWidget(covariant ExperienceLevelSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _lastEmittedLevel = widget.level;
    }
  }

  void _select(int n) {
    if (n == _lastEmittedLevel) return;
    _lastEmittedLevel = n;
    HapticFeedback.selectionClick();
    widget.onLevelChanged(n);
  }

  @override
  Widget build(BuildContext context) {
    final label = ExperienceLevelSlider.levelLabels[widget.level - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tu nivel al volante',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Elegí la opción que mejor te representa.',
          style: AppTextStyles.bodyNormal.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 22),
        _DiscreteLevelRow(
          level: widget.level,
          embeddedOnPanel: widget.embeddedOnPanel,
          onSelect: _select,
        ),
        const SizedBox(height: 22),
        AnimatedSwitcher(
          duration: _kLabelSwitchDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
          child: Text(
            label,
            key: ValueKey<int>(widget.level),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '1 = recién empezás · 5 = solo buscás refuerzo',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyNormal.copyWith(
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _DiscreteLevelRow extends StatelessWidget {
  const _DiscreteLevelRow({
    required this.level,
    required this.embeddedOnPanel,
    required this.onSelect,
  });

  final int level;
  final bool embeddedOnPanel;
  final ValueChanged<int> onSelect;

  static const double _gap = 6;
  static const double _segmentHeight = 50;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(5, (i) {
        final n = i + 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 4 ? _gap : 0),
            child: _LevelSegment(
              index: n,
              selected: n == level,
              embeddedOnPanel: embeddedOnPanel,
              onTap: () => onSelect(n),
            ),
          ),
        );
      }),
    );
  }
}

class _LevelSegment extends StatelessWidget {
  const _LevelSegment({
    required this.index,
    required this.selected,
    required this.embeddedOnPanel,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final bool embeddedOnPanel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Nivel $index de 5',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primary.withValues(alpha: 0.18),
          highlightColor: AppColors.primary.withValues(alpha: 0.08),
          child: AnimatedScale(
            scale: selected ? 1.03 : 1.0,
            duration: _kMotionDuration,
            curve: _kMotionCurve,
            child: AnimatedContainer(
              duration: _kMotionDuration,
              curve: _kMotionCurve,
              height: _DiscreteLevelRow._segmentHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : (embeddedOnPanel
                        ? AppColors.surfaceLighter
                        : AppColors.surfaceLight),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.95)
                      : (embeddedOnPanel
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.surfaceLighter),
                  width: selected ? 1.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: AnimatedDefaultTextStyle(
                duration: _kMotionDuration,
                curve: _kMotionCurve,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: selected ? 17 : 15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? AppColors.textInverse
                      : AppColors.textSecondary,
                  letterSpacing: selected ? 0.2 : 0,
                ),
                child: Text('$index'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
