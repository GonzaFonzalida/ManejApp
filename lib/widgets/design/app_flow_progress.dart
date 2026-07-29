import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';

/// Encabezado de progreso compartido para los pasos de alta y activación.
class AppFlowProgress extends StatelessWidget {
  final String label;
  final double value;

  const AppFlowProgress({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: '${(safeValue * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: safeValue,
              minHeight: 5,
              backgroundColor: AppColors.surfaceLighter,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
