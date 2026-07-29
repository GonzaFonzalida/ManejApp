import 'package:flutter/material.dart';
import '../../config/design_system.dart';

enum AppCardVariant { elevated, outlined, filled }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final AppCardVariant variant;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.panel),
    this.onTap,
    this.backgroundColor,
    this.variant = AppCardVariant.elevated,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surfaceLight;

    late final BoxDecoration decoration;
    switch (variant) {
      case AppCardVariant.elevated:
        decoration = BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.sm,
        );
        break;
      case AppCardVariant.outlined:
        decoration = BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border:
              Border.all(color: AppColors.divider, width: AppStroke.hairline),
        );
        break;
      case AppCardVariant.filled:
        decoration = BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        );
        break;
    }

    final cardContent = Container(
      width: double.infinity,
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
