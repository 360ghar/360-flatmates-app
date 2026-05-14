import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData build({
    required Brightness brightness,
    required AppPalette palette,
  }) {
    final isDark = brightness == Brightness.dark;
    final primary = palette.seedColor;
    final surface = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.card;
    final scaffold = isDark
        ? AppSemanticColors.darkScaffold
        : AppSemanticColors.paper;
    final textPrimary = isDark
        ? AppSemanticColors.paper
        : AppSemanticColors.ink;
    final textSecondary = isDark
        ? AppSemanticColors.paper3
        : AppSemanticColors.ink2;
    final textTertiary = AppSemanticColors.ink3;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.seedColor,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          surface: surface,
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
          outline: AppSemanticColors.line,
          outlineVariant: AppSemanticColors.line,
          error: AppSemanticColors.error,
        );

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.fraunces(
        fontWeight: AppTypography.displayWeight,
        fontSize: AppTypography.displaySize,
        height: AppTypography.displayHeight,
        letterSpacing: AppTypography.displayLetterSpacing,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.fraunces(
        fontWeight: AppTypography.h1Weight,
        fontSize: AppTypography.h1Size,
        height: AppTypography.h1Height,
        letterSpacing: AppTypography.h1LetterSpacing,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontWeight: AppTypography.h2Weight,
        fontSize: AppTypography.h2Size,
        height: AppTypography.h2Height,
        letterSpacing: AppTypography.h2LetterSpacing,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontWeight: AppTypography.h3Weight,
        fontSize: AppTypography.h3Size,
        height: AppTypography.h3Height,
        letterSpacing: AppTypography.h3LetterSpacing,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontWeight: AppTypography.h3Weight,
        fontSize: AppTypography.h3Size,
        height: AppTypography.h3Height,
        letterSpacing: AppTypography.h3LetterSpacing,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontWeight: AppTypography.h4Weight,
        fontSize: AppTypography.h4Size,
        height: AppTypography.h4Height,
        letterSpacing: AppTypography.h4LetterSpacing,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontWeight: AppTypography.bodyLargeWeight,
        fontSize: AppTypography.bodyLargeSize,
        height: AppTypography.bodyLargeHeight,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontWeight: AppTypography.bodyMediumWeight,
        fontSize: AppTypography.bodyMediumSize,
        height: AppTypography.bodyMediumHeight,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontWeight: AppTypography.labelLargeWeight,
        fontSize: AppTypography.labelLargeSize,
        height: AppTypography.labelLargeHeight,
        letterSpacing: AppTypography.labelLargeLetterSpacing,
      ),
      labelMedium: GoogleFonts.inter(
        fontWeight: AppTypography.labelMediumWeight,
        fontSize: AppTypography.labelMediumSize,
        height: AppTypography.labelMediumHeight,
        letterSpacing: AppTypography.labelMediumLetterSpacing,
      ),
      bodySmall: GoogleFonts.inter(
        fontWeight: AppTypography.captionWeight,
        fontSize: AppTypography.captionSize,
        height: AppTypography.captionHeight,
        letterSpacing: AppTypography.captionLetterSpacing,
        color: textTertiary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      dividerColor: AppSemanticColors.line,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1,
        shadowColor: AppSemanticColors.ink.withValues(alpha: 0.06),
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 4,
        shadowColor: AppSemanticColors.ink.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBorder),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppSemanticColors.darkSurface.withValues(alpha: 0.5)
            : surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppSemanticColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(color: AppSemanticColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: const BorderSide(
            color: AppSemanticColors.accent,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? AppSemanticColors.darkSurfaceElevated.withValues(alpha: 0.88)
            : AppSemanticColors.paper.withValues(alpha: 0.88),
        indicatorColor: AppSemanticColors.accent.withValues(alpha: 0.14),
        shadowColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppSemanticColors.accent : AppSemanticColors.ink3,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return (textTheme.labelMedium ?? const TextStyle()).copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppSemanticColors.accent : AppSemanticColors.ink3,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppSemanticColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppSemanticColors.paper4,
          disabledForegroundColor: AppSemanticColors.ink3,
          shadowColor: AppShadows.button.color,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl + AppSpacing.sm,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppSemanticColors.accent,
          side: const BorderSide(color: AppSemanticColors.accent, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl + AppSpacing.sm,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppSemanticColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      dividerTheme: DividerThemeData(
        color: AppSemanticColors.line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
