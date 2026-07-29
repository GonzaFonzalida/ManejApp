import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/design/app_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool destructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    required this.onConfirm,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      title: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 20)),
      content:
          Text(message, style: AppTextStyles.bodyNormal.copyWith(height: 1.45)),
      actions: [
        AppButton(
          fullWidth: false,
          size: AppButtonSize.sm,
          type: AppButtonType.ghost,
          text: cancelText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          fullWidth: false,
          size: AppButtonSize.sm,
          text: confirmText,
          type: destructive ? AppButtonType.danger : AppButtonType.primary,
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
        ),
      ],
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Key? confirmButtonKey,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 20)),
        content: Text(message,
            style: AppTextStyles.bodyNormal.copyWith(height: 1.45)),
        actions: [
          AppButton(
            fullWidth: false,
            size: AppButtonSize.sm,
            type: AppButtonType.ghost,
            text: cancelText,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          AppButton(
            key: confirmButtonKey,
            fullWidth: false,
            size: AppButtonSize.sm,
            text: confirmText,
            type: destructive ? AppButtonType.danger : AppButtonType.primary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}
