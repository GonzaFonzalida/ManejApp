import 'package:flutter/material.dart';
import '../../config/design_system.dart';
import 'app_button.dart';

/// Prioridad visual y semántica (una sola tarjeta visible suele bastar).
enum NextActionPriority {
  /// Requiere atención inmediata (pagos, rechazos).
  urgent,

  /// Importante pronto (documentación, perfil incompleto).
  high,

  /// Acción recomendada habitual.
  standard,

  /// Recordatorio suave o celebración de contexto.
  calm,
}

Color _accent(NextActionPriority p) {
  switch (p) {
    case NextActionPriority.urgent:
      return AppColors.error;
    case NextActionPriority.high:
      return AppColors.warning;
    case NextActionPriority.standard:
      return AppColors.primary;
    case NextActionPriority.calm:
      return AppColors.secondary;
  }
}

/// Patrón reutilizable «Qué hago ahora»: título, contexto, estado opcional y CTA principal.
class NextActionCard extends StatelessWidget {
  final NextActionPriority priority;
  final IconData icon;
  final String title;
  final String description;
  final String? statusLabel;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const NextActionCard({
    super.key,
    required this.priority,
    required this.icon,
    required this.title,
    required this.description,
    this.statusLabel,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accent(priority);
    final surface = Color.alphaBlend(
      accent.withValues(alpha: 0.035),
      AppColors.surfaceLight,
    );

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: AppStroke.hairline,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.panel,
          AppSpacing.md,
          AppSpacing.panel,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.16),
                      width: AppStroke.hairline,
                    ),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Qué hacés ahora',
                              style: AppTextStyles.caption.copyWith(
                                color: accent.withValues(alpha: 0.92),
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (statusLabel != null && statusLabel!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                statusLabel!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        description,
                        style: AppTextStyles.bodyNormal.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: primaryLabel,
                    type: AppButtonType.primary,
                    size: AppButtonSize.md,
                    onPressed: onPrimary,
                  ),
                ),
              ],
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: onSecondary,
                  child: Text(
                    secondaryLabel!,
                    style: AppTextStyles.bodyNormal.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hasta [maxItems] tarjetas (ordenadas por importancia por el caller).
class NextActionStack extends StatelessWidget {
  final List<Widget> children;
  final int maxItems;
  final double spacing;

  const NextActionStack({
    super.key,
    required this.children,
    this.maxItems = 2,
    this.spacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    final visible = children.take(maxItems).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          visible[i],
        ],
      ],
    );
  }
}
