import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base = isDark
        ? AppColors.surfaceLighter
        : AppColors.surfaceLighter.withValues(alpha: 0.65);
    final Color highlight = Color.lerp(
          AppColors.surfaceLight,
          AppColors.primary,
          isDark ? 0.12 : 0.08,
        ) ??
        AppColors.surfaceLight;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceLighter,
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;

  const ListSkeletonLoader({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const SkeletonLoader(
                width: 60,
                height: 60,
                borderRadius: BorderRadius.all(Radius.circular(30))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 14,
                      borderRadius: BorderRadius.circular(4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardSkeletonLoader extends StatelessWidget {
  const CardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(
                width: double.infinity,
                height: 20,
                borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 12),
            SkeletonLoader(
                width: double.infinity,
                height: 16,
                borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            SkeletonLoader(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 16,
                borderRadius: BorderRadius.circular(4)),
          ],
        ),
      ),
    );
  }
}
