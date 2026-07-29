import 'package:flutter/material.dart';

// ─── Colors ───────────────────────────────────────────────────────────────

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF12141C);
  static const Color surfaceLight = Color(0xFF1E2230);
  static const Color surfaceLighter = Color(0xFF2A2F40);

  /// Alias semántico: superficie de card (mismo que surfaceLight).
  static const Color surface = surfaceLight;

  /// Superficie más profunda / variantes de capa.
  static const Color surfaceDark = Color(0xFF161922);

  // Acentos
  static const Color primary = Color(0xFFFCC050);
  static const Color secondary = Color(0xFF8FD9A8);
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF28C76F);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color warning = Color(0xFFFF9F43);
  static const Color info = Color(0xFF4FC3F7);

  // Textos
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A6BE);
  static const Color textInverse = Color(0xFF12141C);

  /// Texto / iconos deshabilitados.
  static const Color disabled = Color(0xFF5C6275);

  /// Scrim / overlays modales.
  static const Color overlay = Color(0xCC000000);

  /// Divisores y bordes sutiles.
  static const Color divider = Color(0xFF3A4055);

  static const Color onPrimary = textInverse;
  static const Color onError = textInverse;
}

// ─── Spacing ────────────────────────────────────────────────────────────────

abstract final class AppSpacing {
  static const double xs = 4;
  static const double xxs = 6;
  static const double sm = 8;
  static const double compact = 12;
  static const double md = 16;
  static const double panel = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double section = 40;
  static const double xxl = 48;
}

// ─── Radius ───────────────────────────────────────────────────────────────

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double panel = 14;
  static const double lg = 16;
  static const double xl = 24;

  /// Pill / botones full-width.
  static const double pill = 100;
}

// ─── Shadows ───────────────────────────────────────────────────────────────

abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Sutil elevación para CTA primario.
  static List<BoxShadow> primaryGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Elevación para tarjeta de rol seleccionada (choose role).
  static List<BoxShadow> roleCardSelected(Color accent) => [
        BoxShadow(
          color: accent.withValues(alpha: 0.22),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}

// ─── Borders ──────────────────────────────────────────────────────────────

abstract final class AppStroke {
  static const double hairline = 1;
  static const double emphasis = 1.5;
}

// ─── Motion ───────────────────────────────────────────────────────────────

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

/// Duraciones que respetan la preferencia del sistema de reducir movimiento.
abstract final class AppMotion {
  static Duration duration(BuildContext context, Duration preferred) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : preferred;
  }
}

abstract final class AppCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOutCubic;
}

// ─── Typography ───────────────────────────────────────────────────────────

class AppTextStyles {
  static TextStyle get displayLarge => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get displayMedium => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get heading => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyNormal => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.35,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: AppColors.textSecondary,
      );

  static TextStyle get buttonText => const TextStyle(
        fontFamily: 'Urbanist',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: AppColors.textInverse,
      );
}

// ─── Legacy layout tokens (migrados desde constants.dart) ─────────────────

/// Tamaños y sombras de layout reutilizables (compat con pantallas migradas).
abstract final class AppSizes {
  static const double paddingSmall = AppSpacing.sm;
  static const double paddingMedium = AppSpacing.md;
  static const double paddingLarge = AppSpacing.lg;
  static const double paddingXLarge = AppSpacing.xl;

  static const double borderRadius = AppRadius.md;
  static const double borderRadiusSmall = AppRadius.sm;
  static const double borderRadiusPill = 28;
  static const double borderRadiusBar = 28;

  static const double buttonHeight = 48;
  static const double logoHeight = 160;

  static List<BoxShadow> get softShadow => AppShadows.sm;

  static List<BoxShadow> get barShadow => [
        BoxShadow(
          color: const Color(0x14000000),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
}

/// Rutas de assets globales.
abstract final class AppAssets {
  static const String logo = 'assets/logo definitivo.jpeg';
}

// ─── Theme ─────────────────────────────────────────────────────────────────

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: AppColors.onPrimary,
        onSecondary: AppColors.textInverse,
        onSurface: AppColors.textPrimary,
        onError: AppColors.onError,
      ),
      dividerColor: AppColors.divider,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineSmall: AppTextStyles.heading,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyNormal,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.buttonText,
        labelSmall: AppTextStyles.labelSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: AppColors.surfaceLighter,
          disabledForegroundColor: AppColors.disabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusPill),
          ),
          textStyle: AppTextStyles.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.heading.copyWith(fontSize: 20),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceLighter,
        contentTextStyle:
            AppTextStyles.bodyNormal.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle:
            AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.textInverse
              : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surfaceLighter,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceLighter,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.divider),
        ),
        textStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLighter,
        hintStyle: AppTextStyles.bodyNormal,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
