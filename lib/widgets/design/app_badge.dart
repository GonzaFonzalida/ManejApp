import 'package:flutter/material.dart';
import '../../config/design_system.dart';

enum AppBadgeVariant { filled, outlined }

/// Chip compacto para estados, pago, rol, verificado.
class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final AppBadgeVariant variant;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.variant = AppBadgeVariant.filled,
    this.icon,
  });

  factory AppBadge.success(String label, {IconData? icon}) =>
      AppBadge(label: label, color: AppColors.success, icon: icon);

  factory AppBadge.warning(String label, {IconData? icon}) =>
      AppBadge(label: label, color: AppColors.warning, icon: icon);

  factory AppBadge.error(String label, {IconData? icon}) =>
      AppBadge(label: label, color: AppColors.error, icon: icon);

  factory AppBadge.info(String label, {IconData? icon}) =>
      AppBadge(label: label, color: AppColors.info, icon: icon);

  factory AppBadge.neutral(String label, {IconData? icon}) =>
      AppBadge(label: label, color: AppColors.textSecondary, icon: icon);

  @override
  Widget build(BuildContext context) {
    final fg =
        variant == AppBadgeVariant.filled ? AppColors.textPrimary : color;
    final bg = variant == AppBadgeVariant.filled
        ? color.withValues(alpha: 0.22)
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: variant == AppBadgeVariant.outlined
            ? Border.all(
                color: color.withValues(alpha: 0.6), width: AppStroke.hairline)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
