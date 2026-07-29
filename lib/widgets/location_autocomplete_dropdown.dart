import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';

class LocationAutocompleteDropdown extends StatelessWidget {
  const LocationAutocompleteDropdown({
    super.key,
    required this.isLoading,
    required this.error,
    required this.suggestions,
    required this.onSelect,
    required this.hasQuery,
  });

  final bool isLoading;
  final String? error;
  final List<Map<String, String>> suggestions;
  final bool hasQuery;
  final ValueChanged<Map<String, String>> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLighter,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25), width: 1),
      ),
      constraints: const BoxConstraints(maxHeight: 240),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 10),
                  Text('Buscando zonas...',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            )
          : error != null
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    error!,
                    style: AppTextStyles.bodyNormal
                        .copyWith(color: AppColors.error, fontSize: 13),
                  ),
                )
              : suggestions.isEmpty && hasQuery
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'No encontramos resultados para esa búsqueda.',
                        style: AppTextStyles.bodyNormal.copyWith(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.divider),
                      itemBuilder: (context, index) {
                        final item = suggestions[index];
                        final display = item['display'] ?? '';
                        final subtitle = item['subtitle'] ?? '';
                        return Semantics(
                          button: true,
                          label: 'Sugerencia de ubicación $display',
                          child: ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined,
                                size: 18, color: AppColors.primary),
                            title: Text(
                              display,
                              style: AppTextStyles.bodyNormal.copyWith(
                                  fontSize: 14, color: AppColors.textPrimary),
                            ),
                            subtitle: subtitle.isNotEmpty
                                ? Text(
                                    subtitle,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textSecondary),
                                  )
                                : null,
                            onTap: () => onSelect(item),
                          ),
                        );
                      },
                    ),
    );
  }
}
