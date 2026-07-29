import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/design/app_card.dart';

/// Ayuda contextual breve: título + pasos o párrafo. Una por pantalla como máximo.
class ContextHelpCard extends StatelessWidget {
  final String title;
  final List<String>? steps;
  final String? body;
  final IconData icon;

  ContextHelpCard({
    super.key,
    required this.title,
    this.steps,
    this.body,
    this.icon = Icons.lightbulb_outline_rounded,
  }) : assert(
          (steps != null && steps.isNotEmpty) ||
              (body != null && body.isNotEmpty),
        );

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                if (steps != null)
                  ...steps!.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${e.key + 1}. ${e.value}',
                            style: AppTextStyles.bodyNormal.copyWith(
                              fontSize: 13,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                if (body != null)
                  Text(
                    body!,
                    style: AppTextStyles.bodyNormal.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
