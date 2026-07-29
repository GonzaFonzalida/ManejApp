import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/utils/app_formatters.dart';
import 'package:manejapp/models/instructor.dart';
import 'package:manejapp/services/profile_map_marker_icon_service.dart';
import 'package:manejapp/screens/reservar_clase_screen.dart';
import 'package:manejapp/widgets/design/app_badge.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_card.dart';
import 'package:manejapp/widgets/responsive_scroll_body.dart';

class InstructorProfileScreen extends StatelessWidget {
  static const routeName = '/instructor-profile';

  final Instructor instructor;
  final LatLng? instructorLocation;

  const InstructorProfileScreen({
    super.key,
    required this.instructor,
    this.instructorLocation,
  });

  static String _transmissionLabel(dynamic raw) {
    final s = raw?.toString().toUpperCase() ?? '';
    if (s.contains('AUTOMATIC')) return 'Automática';
    if (s.contains('MANUAL')) return 'Manual';
    if (s.isEmpty) return '—';
    return raw.toString();
  }

  @override
  Widget build(BuildContext context) {
    final location = instructorLocation ?? const LatLng(-34.6037, -58.3816);
    final userImage =
        instructor.user?.profileImageUrl ?? instructor.user?.profileImage;
    final fullName =
        '${instructor.user?.name ?? ''} ${instructor.user?.surname ?? ''}'
            .trim();
    final displayName = fullName.isEmpty ? 'Instructor' : fullName;

    final estimatedDurationMinutes = 60;
    final hourly = instructor.effectiveHourlyRate;
    final estimatedPrice = ((hourly / 60) * estimatedDurationMinutes).round();

    final zoneText = instructor.addressText?.trim().isNotEmpty == true
        ? instructor.addressText!.trim()
        : (instructor.user?.location?.trim().isNotEmpty == true
            ? instructor.user!.location!.trim()
            : 'Zona indicada en el mapa');

    final firstCar = (instructor.cars != null && instructor.cars!.isNotEmpty)
        ? instructor.cars!.first as Map<String, dynamic>?
        : null;
    final transmissionLabel =
        firstCar != null ? _transmissionLabel(firstCar['transmission']) : null;

    final layout = ResponsiveLayout.instructorProfileLayout(context);
    final mapFraction = layout.mapFraction;
    final sheetTopFraction = layout.sheetTopFraction;
    final h = MediaQuery.sizeOf(context).height;
    final footerScrollPadding =
        ResponsiveLayout.stickyFooterScrollPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h * mapFraction,
            child: _InstructorProfileMapHeader(
              location: location,
              instructor: instructor,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 96,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: AppSpacing.md,
            child: Material(
              color: AppColors.surfaceLight.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned.fill(
            top: h * sheetTopFraction,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl)),
                boxShadow: AppShadows.md,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        footerScrollPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _InstructorHeroBlock(
                            displayName: displayName,
                            userImage: userImage,
                            instructor: instructor,
                            hourly: hourly,
                          ),
                          SizedBox(height: AppSpacing.lg),
                          Text(
                            'Resumen',
                            style: AppTextStyles.labelSmall.copyWith(
                              letterSpacing: 1.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          _QuickStatsGrid(
                            experienceYears: instructor.experienceYears,
                            hourly: hourly,
                            zoneText: zoneText,
                            transmissionLabel: transmissionLabel,
                          ),
                          SizedBox(height: AppSpacing.lg),
                          AppCard(
                            variant: AppCardVariant.outlined,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.event_available_outlined,
                                        color: AppColors.primary, size: 22),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Tu clase',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.md),
                                _KeyValueLine(
                                  label: 'Duración sugerida',
                                  value: '$estimatedDurationMinutes min',
                                ),
                                _KeyValueLine(
                                  label: 'Precio estimado',
                                  value: AppFormatters.ars(estimatedPrice),
                                  emphasize: true,
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Podés cancelar hasta 6 h antes del inicio.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppSpacing.xl),
                          Text(
                            'Sobre el instructor',
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          AppCard(
                            variant: AppCardVariant.filled,
                            backgroundColor: AppColors.surfaceLight,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: _BioSection(
                              text: instructor.bio ??
                                  instructor.description ??
                                  'Este instructor aún no agregó una presentación.',
                            ),
                          ),
                          if (firstCar != null) ...[
                            SizedBox(height: AppSpacing.xl),
                            Text(
                              'Vehículo',
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            AppCard(
                              variant: AppCardVariant.outlined,
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: const Icon(
                                        Icons.directions_car_rounded,
                                        color: AppColors.primary,
                                        size: 28),
                                  ),
                                  SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${firstCar['brand'] ?? ''} ${firstCar['model'] ?? ''}'
                                              .trim(),
                                          style: AppTextStyles.bodyLarge
                                              .copyWith(
                                                  fontWeight: FontWeight.w700),
                                        ),
                                        SizedBox(height: AppSpacing.xxs),
                                        Wrap(
                                          spacing: AppSpacing.sm,
                                          runSpacing: AppSpacing.xs,
                                          children: [
                                            if (firstCar['year'] != null)
                                              AppBadge.neutral(
                                                  '${firstCar['year']}',
                                                  icon: Icons
                                                      .calendar_today_outlined),
                                            if (transmissionLabel != null &&
                                                transmissionLabel != '—')
                                              AppBadge.info(transmissionLabel,
                                                  icon:
                                                      Icons.settings_outlined),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: AppSpacing.lg),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.map_outlined,
                                  color: AppColors.textSecondary, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Zona en el mapa',
                                      style: AppTextStyles.caption.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                    Text(
                                      zoneText,
                                      style: AppTextStyles.bodyNormal
                                          .copyWith(height: 1.35),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0),
                    AppColors.background,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¿Listo para manejar?',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      AppButton(
                        text: 'Reservar clase',
                        type: AppButtonType.primary,
                        size: AppButtonSize.lg,
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            ReservarClaseScreen.routeName,
                            arguments: instructor,
                          );
                        },
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Elegí fecha y horario en el siguiente paso',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorHeroBlock extends StatelessWidget {
  final String displayName;
  final String? userImage;
  final Instructor instructor;
  final double hourly;

  const _InstructorHeroBlock({
    required this.displayName,
    required this.userImage,
    required this.instructor,
    required this.hourly,
  });

  @override
  Widget build(BuildContext context) {
    final rating = instructor.rating;
    final hasRating = rating != null && rating > 0;
    final screenW = MediaQuery.sizeOf(context).width;
    final avatarSize = screenW < 380 ? 80.0 : 104.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.35),
                width: AppStroke.hairline),
            boxShadow: AppShadows.sm,
          ),
          clipBehavior: Clip.antiAlias,
          child: userImage != null && userImage!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: userImage!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceLighter,
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _initialsFallback(),
                )
              : _initialsFallback(),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTextStyles.displayMedium.copyWith(
                  fontSize: 22,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (instructor.isValid == true)
                    AppBadge.success(
                      'Verificado',
                      icon: Icons.verified_outlined,
                    ),
                  if (hasRating)
                    AppBadge.neutral(
                      rating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                    )
                  else
                    AppBadge.neutral('Nuevo', icon: Icons.waving_hand_outlined),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '\$${hourly.round()}',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 20,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' / hora',
                      style: AppTextStyles.bodyNormal.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _initialsFallback() {
    final n = instructor.user?.name ?? 'I';
    final initial = n.trim().isNotEmpty
        ? String.fromCharCode(n.trim().runes.first).toUpperCase()
        : 'I';
    return ColoredBox(
      color: AppColors.surfaceLighter,
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: 40,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  final int experienceYears;
  final double hourly;
  final String zoneText;
  final String? transmissionLabel;

  const _QuickStatsGrid({
    required this.experienceYears,
    required this.hourly,
    required this.zoneText,
    required this.transmissionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.timeline_rounded,
                label: 'Experiencia',
                value: experienceYears == 1 ? '1 año' : '$experienceYears años',
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatTile(
                icon: Icons.payments_outlined,
                label: 'Tarifa',
                value: '\$${hourly.round()}/h',
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: (transmissionLabel != null && transmissionLabel != '—')
                  ? 1
                  : 2,
              child: _StatTile(
                icon: Icons.place_outlined,
                label: 'Zona',
                value: zoneText.length > 42
                    ? '${zoneText.substring(0, 40)}…'
                    : zoneText,
                multiline: true,
              ),
            ),
            if (transmissionLabel != null && transmissionLabel != '—') ...[
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  icon: Icons.settings_outlined,
                  label: 'Caja',
                  value: transmissionLabel!,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.outlined,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          SizedBox(height: AppSpacing.sm),
          Text(
            label.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTextStyles.bodyNormal.copyWith(
              fontWeight: FontWeight.w700,
              height: multiline ? 1.35 : 1.2,
            ),
            maxLines: multiline ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _KeyValueLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _KeyValueLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyNormal
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: emphasize
                  ? AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w800, color: AppColors.primary)
                  : AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructorProfileMapHeader extends StatefulWidget {
  final LatLng location;
  final Instructor instructor;

  const _InstructorProfileMapHeader({
    required this.location,
    required this.instructor,
  });

  @override
  State<_InstructorProfileMapHeader> createState() =>
      _InstructorProfileMapHeaderState();
}

class _InstructorProfileMapHeaderState
    extends State<_InstructorProfileMapHeader> {
  static const double _cameraLatOffsetNorth = 0.00024;

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMarker());
  }

  @override
  void didUpdateWidget(_InstructorProfileMapHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instructor.id != widget.instructor.id ||
        oldWidget.location != widget.location) {
      _loadMarker();
    }
  }

  Future<void> _loadMarker() async {
    if (!mounted) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final url = widget.instructor.user?.profileImageUrl ??
        widget.instructor.user?.profileImage;
    final name = widget.instructor.user?.name ?? '';
    final initial = name.trim().isNotEmpty
        ? String.fromCharCode(name.trim().runes.first).toUpperCase()
        : 'I';
    final icon =
        await ProfileMapMarkerIconService.instance.descriptorForProfile(
      devicePixelRatio: dpr,
      imageUrl: url,
      fallbackLabel: initial,
      fallbackColor: AppColors.secondary,
    );
    if (!mounted) return;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('instructor'),
          position: widget.location,
          icon: icon,
          anchor: ProfileMapMarkerIconService.anchorFor(
              ProfileMapMarkerAnchorMode.geographicCenter),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      padding: const EdgeInsets.only(top: 32, left: 8, right: 8, bottom: 16),
      initialCameraPosition: CameraPosition(
        target: LatLng(
          widget.location.latitude + _cameraLatOffsetNorth,
          widget.location.longitude,
        ),
        zoom: 14.42,
      ),
      circles: {
        Circle(
          circleId: const CircleId('coverage'),
          center: widget.location,
          radius: 360,
          fillColor: AppColors.primary.withValues(alpha: 0.18),
          strokeColor: AppColors.primary.withValues(alpha: 0.55),
          strokeWidth: 2,
        ),
      },
      markers: _markers,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }
}

class _BioSection extends StatefulWidget {
  final String text;

  const _BioSection({required this.text});

  @override
  State<_BioSection> createState() => _BioSectionState();
}

class _BioSectionState extends State<_BioSection> {
  bool _expanded = false;
  static const int _previewChars = 220;

  @override
  Widget build(BuildContext context) {
    final t = widget.text.trim();
    final long = t.length > _previewChars;
    final shown =
        _expanded || !long ? t : '${t.substring(0, _previewChars).trim()}…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shown,
          style: AppTextStyles.bodyNormal.copyWith(
            height: 1.55,
            fontSize: 15,
            color: AppColors.textPrimary.withValues(alpha: 0.92),
          ),
        ),
        if (long)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _expanded ? 'Ver menos' : 'Leer más',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}
