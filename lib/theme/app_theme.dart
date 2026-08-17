import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const primary = Color(0xFF010A25);
  static const primaryLight = Color(0xFF17213C);
  static const accent = Color(0xFFFF725E);

  static const neutral50 = Color(0xFFF9F9FF);
  static const neutral100 = Color(0xFFF1F3FF);
  static const neutral200 = Color(0xFFEAEDFC);
  static const neutral300 = Color(0xFFDFE2F0);
  static const neutral400 = Color(0xFFC6C6CE);
  static const neutral500 = Color(0xFF76767E);
  static const neutral600 = Color(0xFF5D5E66);
  static const neutral700 = Color(0xFF45464D);
  static const neutral800 = Color(0xFF2C303B);
  static const neutral900 = Color(0xFF171B25);

  static const background = neutral50;
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = neutral900;
  static const textSecondary = neutral600;
  static const outline = neutral400;

  static const success = Color(0xFF268065);
  static const successContainer = Color(0xFFE7F4EF);
  static const warning = Color(0xFF9A6817);
  static const pendingContainer = Color(0xFFFFF2D8);
  static const error = Color(0xFFB84A56);

  static const darkBackground = Color(0xFF080C17);
  static const darkSurface = Color(0xFF101522);
  static const darkSurfaceHigh = Color(0xFF1A2030);
  static const darkOutline = Color(0xFF343B4C);
}

abstract final class AppRadius {
  static const double small = 8;
  static const double medium = 8;
  static const double button = pill;
  static const double pill = 999;
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppTheme {
  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? const Color(0xFFB8C6F2) : AppColors.primary,
      onPrimary: dark ? AppColors.primary : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF263354)
          : const Color(0xFFDAE1FF),
      onPrimaryContainer: dark ? const Color(0xFFDDE5FF) : AppColors.primary,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: dark
          ? const Color(0xFF552D29)
          : const Color(0xFFFFE9E5),
      onSecondaryContainer: dark
          ? const Color(0xFFFFDAD4)
          : const Color(0xFF7C2D23),
      tertiary: dark ? const Color(0xFF74CDB0) : AppColors.success,
      onTertiary: dark ? const Color(0xFF00382B) : Colors.white,
      error: dark ? const Color(0xFFFFB2B9) : AppColors.error,
      onError: dark ? const Color(0xFF680019) : Colors.white,
      surface: dark ? AppColors.darkSurface : AppColors.surface,
      onSurface: dark ? const Color(0xFFE8E9EE) : AppColors.textPrimary,
      surfaceContainerHighest: dark
          ? AppColors.darkSurfaceHigh
          : AppColors.neutral300,
      onSurfaceVariant: dark
          ? const Color(0xFFAEB2BD)
          : AppColors.textSecondary,
      outline: dark ? AppColors.darkOutline : AppColors.outline,
      outlineVariant: dark ? const Color(0xFF242B3A) : AppColors.neutral300,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? AppColors.neutral100 : AppColors.neutral900,
      onInverseSurface: dark ? AppColors.neutral900 : Colors.white,
      inversePrimary: dark ? AppColors.primary : const Color(0xFFB8C6F2),
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final typography = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        height: 1.08,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: scheme.onSurface,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 26,
        height: 1.16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: scheme.onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
        color: scheme.onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: scheme.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.48,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? AppColors.darkBackground
          : AppColors.background,
      textTheme: typography,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _PremiumPageTransitionBuilder(),
          TargetPlatform.iOS: _PremiumPageTransitionBuilder(),
          TargetPlatform.macOS: _PremiumPageTransitionBuilder(),
          TargetPlatform.windows: _PremiumPageTransitionBuilder(),
          TargetPlatform.linux: _PremiumPageTransitionBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.darkBackground : AppColors.background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: typography.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: AppColors.primary.withValues(alpha: dark ? .20 : .08),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: .12)
                : dark
                ? const Color(0xFFDCE4FF)
                : AppColors.primary,
          ),
          foregroundColor: WidgetStatePropertyAll(
            dark ? AppColors.primary : Colors.white,
          ),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: .10),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: .07),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.pressed)
                  ? scheme.primary.withValues(alpha: .55)
                  : scheme.outline,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size(44, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        hintStyle: typography.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: .75),
        ),
        labelStyle: typography.bodyMedium,
        floatingLabelStyle: typography.labelMedium?.copyWith(
          color: scheme.primary,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: scheme.error.withValues(alpha: .7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide(color: scheme.outline),
        labelStyle: typography.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: typography.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
    );
  }
}

class _PremiumPageTransitionBuilder extends PageTransitionsBuilder {
  const _PremiumPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.025, .012),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
