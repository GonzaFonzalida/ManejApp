import 'package:flutter/material.dart';

/// Helpers for responsive sizing on small or short viewports (common on Android).
class ResponsiveLayout {
  ResponsiveLayout._();

  static double availableHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return size.height - padding.top - padding.bottom;
  }

  /// Height for embedded map pickers inside scrollable forms.
  static double embeddedMapHeight(BuildContext context,
      {double fraction = 0.32}) {
    return (availableHeight(context) * fraction).clamp(160.0, 320.0);
  }

  /// Hero / onboarding illustration size that scales down on short screens.
  static double heroIconSize(BuildContext context,
      {double max = 200, double min = 120}) {
    final h = availableHeight(context);
    if (h < 560) return min;
    if (h < 640) return 160;
    return max;
  }

  /// Scroll padding that accounts for keyboard, safe-area and large text.
  static EdgeInsets scrollPadding(
    BuildContext context, {
    EdgeInsetsGeometry base = const EdgeInsets.all(20),
  }) {
    final resolved = base.resolve(Directionality.of(context));
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final textExtra = _largeTextExtraBottom(context);
    return EdgeInsets.fromLTRB(
      resolved.left,
      resolved.top,
      resolved.right,
      resolved.bottom + keyboard + textExtra + (keyboard > 0 ? 12 : safeBottom),
    );
  }

  /// Bottom padding so scroll content clears a sticky footer CTA.
  static double stickyFooterScrollPadding(BuildContext context,
      {double base = 112}) {
    return MediaQuery.textScalerOf(context).scale(base) +
        MediaQuery.paddingOf(context).bottom;
  }

  /// Draggable sheet sizes for explore/home map screens.
  static ({double initial, double min, double max}) exploreSheetSizes(
      BuildContext context) {
    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return (initial: 0.52, min: 0.26, max: 0.94);
    }
    final h = availableHeight(context);
    if (h < 560) {
      return (initial: 0.42, min: 0.20, max: 0.90);
    }
    return (initial: 0.38, min: 0.18, max: 0.92);
  }

  /// Map + bottom sheet layout for instructor profile.
  static ({double mapFraction, double sheetTopFraction})
      instructorProfileLayout(BuildContext context) {
    if (MediaQuery.orientationOf(context) == Orientation.landscape) {
      return (mapFraction: 0.22, sheetTopFraction: 0.16);
    }
    final h = availableHeight(context);
    if (h < 560) {
      return (mapFraction: 0.24, sheetTopFraction: 0.18);
    }
    if (h < 640) {
      return (mapFraction: 0.28, sheetTopFraction: 0.22);
    }
    return (mapFraction: 0.34, sheetTopFraction: 0.28);
  }

  static double _largeTextExtraBottom(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    if (scale <= 1.15) return 0;
    return (scale - 1) * 24;
  }
}

/// Safe, keyboard-aware scroll body for screens that may exceed the viewport.
class ResponsiveScrollBody extends StatelessWidget {
  const ResponsiveScrollBody({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.centerWhenShort = false,
    this.safeArea = true,
    this.keyboardAware = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool centerWhenShort;
  final bool safeArea;
  final bool keyboardAware;

  @override
  Widget build(BuildContext context) {
    final effectivePadding = keyboardAware
        ? ResponsiveLayout.scrollPadding(context,
            base: padding ?? const EdgeInsets.all(20))
        : (padding ?? const EdgeInsets.all(20));

    Widget scroll = SingleChildScrollView(
      controller: controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: effectivePadding,
      child: centerWhenShort
          ? ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: ResponsiveLayout.availableHeight(context) -
                    effectivePadding.vertical,
              ),
              child: child,
            )
          : child,
    );

    if (safeArea) {
      scroll = SafeArea(child: scroll);
    }

    return scroll;
  }
}
