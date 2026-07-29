import 'package:flutter/material.dart';
import '../../config/design_system.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.semanticLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String? semanticLabel;
}

class AppBottomNav extends StatelessWidget {
  static const studentItems = <AppBottomNavItem>[
    AppBottomNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Inicio',
    ),
    AppBottomNavItem(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: 'Reservas',
    ),
    AppBottomNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
    AppBottomNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Ajustes',
    ),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  /// Keys por índice (p. ej. integration tests).
  final Map<int, Key>? itemKeys;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = studentItems,
    this.itemKeys,
  }) : assert(items.length >= 2);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Semantics(
        container: true,
        label: 'Navegación principal',
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.7),
              width: AppStroke.hairline,
            ),
            boxShadow: AppShadows.md,
          ),
          child: Row(
            children: List.generate(
              items.length,
              (index) => Expanded(child: _buildNavItem(context, index)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index) {
    final item = items[index];
    final isSelected = currentIndex == index;
    final foreground =
        isSelected ? AppColors.textInverse : AppColors.textSecondary;

    return Semantics(
      key: itemKeys?[index],
      button: true,
      selected: isSelected,
      label: item.semanticLabel ?? item.label,
      excludeSemantics: true,
      child: Tooltip(
        message: item.semanticLabel ?? item.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AnimatedContainer(
              duration: AppDurations.normal,
              curve: AppCurves.emphasized,
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    color: foreground,
                    size: 23,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: foreground,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
