import 'package:flutter/material.dart';
import '../../config/design_system.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
              boxShadow: AppShadows.sm,
            ),
            child: Icon(icon,
                size: 40,
                color: AppColors.textSecondary.withValues(alpha: 0.85)),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(fontSize: 20),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: AppSpacing.xl),
            AppButton(
              text: actionLabel!,
              onPressed: onAction,
              type: AppButtonType.secondary,
              size: AppButtonSize.md,
            ),
          ],
        ],
      ),
    );
  }
}
