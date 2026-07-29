import 'package:flutter/material.dart';
import '../../config/design_system.dart';

enum AppButtonType { primary, secondary, whatsapp, outline, ghost, danger }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final AppButtonSize size;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.padding,
    this.size = AppButtonSize.lg,
    this.fullWidth = true,
  });

  double get _height {
    switch (size) {
      case AppButtonSize.sm:
        return 44;
      case AppButtonSize.md:
        return 50;
      case AppButtonSize.lg:
        return 56;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.borderRadiusPill);
    final disabled = onPressed == null && !isLoading;

    if (isLoading) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _height),
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceLighter,
              disabledBackgroundColor: AppColors.surfaceLighter,
              shape: RoundedRectangleBorder(borderRadius: radius),
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
              ),
            ),
          ),
        ),
      );
    }

    if (type == AppButtonType.ghost) {
      final style = TextButton.styleFrom(
        foregroundColor: disabled ? AppColors.disabled : AppColors.primary,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle:
            AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: radius),
      );
      final btn = TextButton(
        onPressed: disabled ? null : onPressed,
        style: style,
        child: _buildLabel(),
      );
      return fullWidth
          ? SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: _height),
                child: Center(child: btn),
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(minHeight: _height), child: btn);
    }

    late final Color bgColor;
    late final Color fgColor;
    BorderSide? side;
    var elevation = 0.0;
    Color? shadowColor;

    switch (type) {
      case AppButtonType.primary:
        bgColor = AppColors.primary;
        fgColor = AppColors.textInverse;
        side = null;
        elevation = disabled ? 0 : 2;
        shadowColor = AppColors.primary.withValues(alpha: 0.35);
        break;
      case AppButtonType.secondary:
        bgColor = AppColors.surfaceLighter;
        fgColor = AppColors.textPrimary;
        side = null;
        break;
      case AppButtonType.whatsapp:
        bgColor = AppColors.whatsapp;
        fgColor = AppColors.textInverse;
        side = null;
        elevation = disabled ? 0 : 4;
        shadowColor = AppColors.whatsapp.withValues(alpha: 0.45);
        break;
      case AppButtonType.outline:
        bgColor = Colors.transparent;
        fgColor = AppColors.textPrimary;
        side = BorderSide(color: AppColors.divider, width: AppStroke.hairline);
        break;
      case AppButtonType.danger:
        bgColor = AppColors.error;
        fgColor = AppColors.textInverse;
        side = null;
        elevation = disabled ? 0 : 1;
        break;
      case AppButtonType.ghost:
        bgColor = Colors.transparent;
        fgColor = AppColors.primary;
        side = null;
        break;
    }

    final effectiveBg = disabled
        ? (type == AppButtonType.outline
            ? Colors.transparent
            : type == AppButtonType.secondary
                ? AppColors.surfaceDark
                : type == AppButtonType.whatsapp
                    ? AppColors.whatsapp.withValues(alpha: 0.35)
                    : type == AppButtonType.danger
                        ? AppColors.error.withValues(alpha: 0.35)
                        : AppColors.surfaceLighter)
        : bgColor;

    final effectiveFg = disabled ? AppColors.disabled : fgColor;

    final textStyle = (type == AppButtonType.primary ||
            type == AppButtonType.whatsapp ||
            type == AppButtonType.danger)
        ? AppTextStyles.buttonText.copyWith(color: effectiveFg)
        : AppTextStyles.bodyLarge
            .copyWith(fontWeight: FontWeight.w700, color: effectiveFg);

    final style = ElevatedButton.styleFrom(
      backgroundColor: effectiveBg,
      foregroundColor: effectiveFg,
      disabledBackgroundColor: effectiveBg,
      disabledForegroundColor: AppColors.disabled,
      elevation: elevation,
      shadowColor: shadowColor,
      side: side,
      shape: RoundedRectangleBorder(borderRadius: radius),
      textStyle: textStyle,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _height),
        child: Opacity(
          opacity: disabled && type != AppButtonType.outline ? 0.55 : 1,
          child: ElevatedButton(
            onPressed: disabled ? null : onPressed,
            style: style,
            child: _buildLabel(),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel() {
    if (icon != null) {
      if (text.isEmpty) {
        return Icon(icon, size: 22);
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    return Text(text, maxLines: 2, textAlign: TextAlign.center);
  }
}
