import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../config/design_system.dart';

enum AppAvatarSize { sm, md, lg }

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final AppAvatarSize size;
  final bool showBorder;
  final double? diameter;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AppAvatarSize.md,
    this.showBorder = false,
    this.diameter,
  });

  double get _diameter {
    switch (size) {
      case AppAvatarSize.sm:
        return 36;
      case AppAvatarSize.md:
        return 48;
      case AppAvatarSize.lg:
        return 72;
    }
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts[0];
      return s.isEmpty ? '?' : s.substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final d = diameter ?? _diameter;
    final url = imageUrl?.trim();
    final hasImage = url != null && url.isNotEmpty;

    Widget child;
    if (hasImage) {
      child = ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: d,
          height: d,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: d,
            height: d,
            color: AppColors.surfaceLighter,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => _fallbackCircle(d),
        ),
      );
    } else {
      child = _fallbackCircle(d);
    }

    return Semantics(
      image: true,
      label: 'Foto de ${name.trim().isEmpty ? 'perfil' : name.trim()}',
      child: ExcludeSemantics(
        child: Container(
          width: d,
          height: d,
          decoration: showBorder
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.divider,
                    width: AppStroke.hairline,
                  ),
                )
              : null,
          child: child,
        ),
      ),
    );
  }

  Widget _fallbackCircle(double d) {
    return Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceLighter,
      ),
      child: Text(
        _initials,
        style: AppTextStyles.heading.copyWith(
          fontSize: d * 0.36,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
