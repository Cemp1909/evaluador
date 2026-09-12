import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0A122C);
  static const primaryLight = Color(0xFF1E284A);
  static const accent = Color(0xFFFF644E);
  static const accentLight = Color(0xFFFF8B7A);

  static const neutral50 = Color(0xFFF8F9FE);
  static const neutral100 = Color(0xFFEFF1F9);
  static const neutral200 = Color(0xFFE4E7F4);
  static const neutral300 = Color(0xFFD6DAEC);
  static const neutral400 = Color(0xFFB8BDD2);
  static const neutral500 = Color(0xFF7D839E);
  static const neutral600 = Color(0xFF5B617C);
  static const neutral700 = Color(0xFF3F455D);
  static const neutral800 = Color(0xFF22273B);
  static const neutral900 = Color(0xFF0F1424);

  static const background = neutral50;
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = neutral900;
  static const textSecondary = neutral600;
  static const outline = Color(0xFFD0D5E6);

  static const success = Color(0xFF1B8462);
  static const successContainer = Color(0xFFE8F6F1);
  static const warning = Color(0xFFB87814);
  static const pendingContainer = Color(0xFFFFF4DF);
  static const error = Color(0xFFD33847);
  static const errorContainer = Color(0xFFFFECEF);

  static const darkBackground = Color(0xFF0A0E18);
  static const darkSurface = Color(0xFF121726);
  static const darkSurfaceHigh = Color(0xFF1C243A);
  static const darkOutline = Color(0xFF2E3954);
}

abstract final class AppRadius {
  static const double small = 10;
  static const double medium = 16;
  static const double large = 22;
  static const double button = 14;
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
      primary: dark ? const Color(0xFFBAC7FA) : AppColors.primary,
      onPrimary: dark ? AppColors.primary : Colors.white,
      primaryContainer: dark
          ? const Color(0xFF242F50)
          : const Color(0xFFE6EBFF),
      onPrimaryContainer: dark
          ? const Color(0xFFDEE5FF)
          : const Color(0xFF0A122C),
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      secondaryContainer: dark
          ? const Color(0xFF552822)
          : const Color(0xFFFFE8E4),
      onSecondaryContainer: dark
          ? const Color(0xFFFFDAD4)
          : const Color(0xFF7A2016),
      tertiary: dark ? const Color(0xFF72D2B3) : AppColors.success,
      onTertiary: dark ? const Color(0xFF003828) : Colors.white,
      tertiaryContainer: dark
          ? const Color(0xFF0D3B2E)
          : AppColors.successContainer,
      onTertiaryContainer: dark
          ? const Color(0xFF90ECCB)
          : const Color(0xFF084D37),
      error: dark ? const Color(0xFFFFB3B9) : AppColors.error,
      onError: dark ? const Color(0xFF680018) : Colors.white,
      errorContainer: dark ? const Color(0xFF5A141E) : AppColors.errorContainer,
      onErrorContainer: dark
          ? const Color(0xFFFFD9DD)
          : const Color(0xFF78111D),
      surface: dark ? AppColors.darkSurface : AppColors.surface,
      onSurface: dark ? const Color(0xFFE6E8F2) : AppColors.textPrimary,
      surfaceContainerHighest: dark
          ? AppColors.darkSurfaceHigh
          : AppColors.neutral200,
      onSurfaceVariant: dark
          ? const Color(0xFFA6ADCA)
          : AppColors.textSecondary,
      outline: dark ? AppColors.darkOutline : AppColors.outline,
      outlineVariant: dark ? const Color(0xFF232C44) : AppColors.neutral200,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: dark ? AppColors.neutral100 : AppColors.neutral900,
      onInverseSurface: dark ? AppColors.neutral900 : Colors.white,
      inversePrimary: dark ? AppColors.primary : const Color(0xFFBAC7FA),
    );

    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final typography = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.inter(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.1,
        color: scheme.onSurface,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: scheme.onSurface,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 19,
        height: 1.26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: scheme.onSurface,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: scheme.onSurface,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
        color: scheme.onSurface,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        height: 1.48,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.46,
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
        letterSpacing: 0.0,
        color: scheme.onSurface,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: scheme.onSurface,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: scheme.onSurface,
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
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: dark ? .22 : .06),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: dark ? .7 : .8),
            width: 1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface.withValues(alpha: .12)
                : dark
                ? const Color(0xFFBAC7FA)
                : AppColors.primary,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? scheme.onSurface
                : dark
                ? AppColors.primary
                : Colors.white,
          ),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed) ? 0 : 0.5,
          ),
          shadowColor: WidgetStatePropertyAll(
            AppColors.primary.withValues(alpha: 0.18),
          ),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: .12),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 1,
          shadowColor: AppColors.primary.withValues(alpha: dark ? .25 : .08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(color: scheme.outlineVariant),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          ),
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          backgroundColor: WidgetStatePropertyAll(
            scheme.surface.withValues(alpha: dark ? 0.3 : 0.6),
          ),
          overlayColor: WidgetStatePropertyAll(
            scheme.primary.withValues(alpha: .06),
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.pressed)
                  ? scheme.primary.withValues(alpha: .6)
                  : scheme.outline,
              width: 1.1,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: typography.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: .7),
        ),
        labelStyle: typography.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: typography.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(
            color: scheme.error.withValues(alpha: .75),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: dark ? .5 : .8),
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        disabledColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: typography.labelMedium?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle: typography.labelMedium?.copyWith(
          color: scheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: AppColors.primary.withValues(alpha: dark ? .4 : .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: dark ? const Color(0xFFBAC7FA) : AppColors.primary,
        foregroundColor: dark ? AppColors.primary : Colors.white,
        elevation: 3,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
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
