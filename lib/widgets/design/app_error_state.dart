import 'package:flutter/material.dart';
import '../../config/design_system.dart';
import 'app_button.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final Key? retryButtonKey;

  const AppErrorState({
    super.key,
    this.title = 'Algo salió mal',
    this.message,
    this.onRetry,
    this.retryLabel = 'Reintentar',
    this.retryButtonKey,
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
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: AppColors.error.withValues(alpha: 0.9),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(fontSize: 20),
          ),
          if (message != null && message!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyNormal.copyWith(height: 1.45),
            ),
          ],
          if (onRetry != null) ...[
            SizedBox(height: AppSpacing.xl),
            AppButton(
              key: retryButtonKey,
              text: retryLabel,
              onPressed: onRetry,
              type: AppButtonType.outline,
              icon: Icons.refresh_rounded,
              size: AppButtonSize.md,
            ),
          ],
        ],
      ),
    );
  }
}
