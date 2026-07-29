import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/widgets/skeleton_loader.dart';

/// Carga tipo detalle de reserva / clase (AppBar + bloque principal + filas).
class BookingDetailLoadingScaffold extends StatelessWidget {
  const BookingDetailLoadingScaffold({
    super.key,
    this.title = 'Cargando…',
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          title,
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.panel),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(
              width: double.infinity,
              height: 112,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            const SizedBox(height: AppSpacing.lg),
            const SkeletonLoader(
              width: 180,
              height: 22,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            const SizedBox(height: AppSpacing.sm),
            SkeletonLoader(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            SkeletonLoader(
              width: MediaQuery.sizeOf(context).width * 0.72,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: AppSpacing.xl),
            SkeletonLoader(
              width: double.infinity,
              height: 52,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            const SizedBox(height: 12),
            SkeletonLoader(
              width: double.infinity,
              height: 52,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder mientras cargan resultados de búsqueda (lista de instructores).
/// Sin scroll interno: pensado para ir dentro de [SliverFillRemaining] / columna.
class HomeInstructorResultsSkeleton extends StatelessWidget {
  const HomeInstructorResultsSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(
                          width: double.infinity,
                          height: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 10),
                        SkeletonLoader(
                          width: w * 0.45,
                          height: 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        SkeletonLoader(
                          width: w * 0.35,
                          height: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Grilla de horarios (reservar clase).
class SlotPickerSkeleton extends StatelessWidget {
  const SlotPickerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonLoader(
        width: double.infinity,
        height: 40,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    );
  }
}

/// Lista de franjas de agenda del instructor.
class InstructorScheduleSkeleton extends StatelessWidget {
  const InstructorScheduleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => SkeletonLoader(
        width: double.infinity,
        height: 64,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}
