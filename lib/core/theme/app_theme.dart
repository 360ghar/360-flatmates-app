// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  /// Builds the Airbnb-aligned Material 3 theme.
  ///
  /// Single brand primary (Rausch). Palette switching is not supported.
  static ThemeData build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    const primary = AppSemanticColors.primary;
    final surface = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.canvas;
    final scaffold = isDark
        ? AppSemanticColors.darkScaffold
        : AppSemanticColors.canvas;
    final textPrimary = isDark
        ? AppSemanticColors.darkInk
        : AppSemanticColors.ink;
    final textSecondary = isDark
        ? AppSemanticColors.darkBody
        : AppSemanticColors.body;
    final textTertiary = isDark
        ? AppSemanticColors.darkMuted
        : AppSemanticColors.muted;
    final outline = isDark
        ? AppSemanticColors.darkHairline
        : AppSemanticColors.hairline;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: AppSemanticColors.onPrimary,
          primaryContainer: isDark
              ? AppSemanticColors.coralSoftDark
              : AppSemanticColors.primarySoft,
          onPrimaryContainer: isDark ? AppSemanticColors.darkInk : primary,
          surface: surface,
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
          outline: outline,
          outlineVariant: outline,
          error: AppSemanticColors.error,
          onError: AppSemanticColors.onPrimary,
          surfaceTint: Colors.transparent,
          shadow: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
        );

    TextStyle inter({
      required FontWeight fontWeight,
      required double fontSize,
      required double height,
      double letterSpacing = 0,
      Color? color,
    }) {
      return GoogleFonts.inter(
        fontWeight: fontWeight,
        fontSize: fontSize,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );
    }

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: inter(
        fontWeight: AppTypography.ratingDisplayWeight,
        fontSize: AppTypography.ratingDisplaySize,
        height: AppTypography.ratingDisplayHeight,
        letterSpacing: AppTypography.ratingDisplayLetterSpacing,
        color: textPrimary,
      ),
      displayMedium: inter(
        fontWeight: AppTypography.displayXlWeight,
        fontSize: AppTypography.displayXlSize,
        height: AppTypography.displayXlHeight,
        color: textPrimary,
      ),
      displaySmall: inter(
        fontWeight: AppTypography.displayLgWeight,
        fontSize: AppTypography.displayLgSize,
        height: AppTypography.displayLgHeight,
        letterSpacing: AppTypography.displayLgLetterSpacing,
        color: textPrimary,
      ),
      headlineLarge: inter(
        fontWeight: AppTypography.displayXlWeight,
        fontSize: AppTypography.displayXlSize,
        height: AppTypography.displayXlHeight,
        color: textPrimary,
      ),
      headlineMedium: inter(
        fontWeight: AppTypography.displayMdWeight,
        fontSize: AppTypography.displayMdSize,
        height: AppTypography.displayMdHeight,
        color: textPrimary,
      ),
      headlineSmall: inter(
        fontWeight: AppTypography.displaySmWeight,
        fontSize: AppTypography.displaySmSize,
        height: AppTypography.displaySmHeight,
        letterSpacing: AppTypography.displaySmLetterSpacing,
        color: textPrimary,
      ),
      titleLarge: inter(
        fontWeight: AppTypography.titleMdWeight,
        fontSize: AppTypography.titleMdSize,
        height: AppTypography.titleMdHeight,
        color: textPrimary,
      ),
      titleMedium: inter(
        fontWeight: AppTypography.titleMdWeight,
        fontSize: AppTypography.titleMdSize,
        height: AppTypography.titleMdHeight,
        color: textPrimary,
      ),
      titleSmall: inter(
        fontWeight: AppTypography.titleSmWeight,
        fontSize: AppTypography.titleSmSize,
        height: AppTypography.titleSmHeight,
        color: textPrimary,
      ),
      bodyLarge: inter(
        fontWeight: AppTypography.bodyMdWeight,
        fontSize: AppTypography.bodyMdSize,
        height: AppTypography.bodyMdHeight,
        color: textPrimary,
      ),
      bodyMedium: inter(
        fontWeight: AppTypography.bodySmWeight,
        fontSize: AppTypography.bodySmSize,
        height: AppTypography.bodySmHeight,
        color: textSecondary,
      ),
      bodySmall: inter(
        fontWeight: AppTypography.captionSmWeight,
        fontSize: AppTypography.captionSmSize,
        height: AppTypography.captionSmHeight,
        color: textTertiary,
      ),
      labelLarge: inter(
        fontWeight: AppTypography.buttonMdWeight,
        fontSize: AppTypography.buttonMdSize,
        height: AppTypography.buttonMdHeight,
        color: textPrimary,
      ),
      labelMedium: inter(
        fontWeight: AppTypography.buttonSmWeight,
        fontSize: AppTypography.buttonSmSize,
        height: AppTypography.buttonSmHeight,
        color: textPrimary,
      ),
      labelSmall: inter(
        fontWeight: AppTypography.badgeWeight,
        fontSize: AppTypography.badgeSize,
        height: AppTypography.badgeHeight,
        color: textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      dividerColor: outline,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        toolbarHeight: 56,
        titleSpacing: AppSpacing.sm,
        titleTextStyle: inter(
          fontWeight: AppTypography.titleMdWeight,
          fontSize: AppTypography.titleMdSize,
          height: AppTypography.titleMdHeight,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 20),
        actionsIconTheme: IconThemeData(color: textPrimary, size: 20),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBarrierColor: AppSemanticColors.scrim50,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetTopBorder,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppSemanticColors.darkSurface
            : AppSemanticColors.canvas,
        border: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: BorderSide(color: textPrimary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: BorderSide(color: AppSemanticColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.smBorder,
          borderSide: BorderSide(color: AppSemanticColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.base,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: textTertiary),
        labelStyle: textTheme.labelMedium?.copyWith(color: textTertiary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffold,
        indicatorColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 64,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? textPrimary : textTertiary,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return (textTheme.labelMedium ?? const TextStyle()).copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
            color: selected ? textPrimary : textTertiary,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppSemanticColors.primaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppSemanticColors.primaryActive;
            }
            return AppSemanticColors.primary;
          }),
          foregroundColor: WidgetStateProperty.all(AppSemanticColors.onPrimary),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
          ),
          textStyle: WidgetStateProperty.all(
            inter(
              fontWeight: AppTypography.buttonMdWeight,
              fontSize: AppTypography.buttonMdSize,
              height: AppTypography.buttonMdHeight,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            isDark ? AppSemanticColors.darkSurface : AppSemanticColors.canvas,
          ),
          foregroundColor: WidgetStateProperty.all(textPrimary),
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 23, vertical: 13),
          ),
          side: WidgetStateProperty.all(BorderSide(color: textPrimary)),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
          ),
          textStyle: WidgetStateProperty.all(
            inter(
              fontWeight: AppTypography.buttonMdWeight,
              fontSize: AppTypography.buttonMdSize,
              height: AppTypography.buttonMdHeight,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(textPrimary),
          textStyle: WidgetStateProperty.all(
            inter(
              fontWeight: AppTypography.buttonMdWeight,
              fontSize: AppTypography.buttonMdSize,
              height: AppTypography.buttonMdHeight,
            ),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? AppSemanticColors.darkSurfaceElevated
            : AppSemanticColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppSemanticColors.onPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? AppSemanticColors.darkSurfaceElevated
            : AppSemanticColors.surfaceSoft,
        selectedColor: isDark
            ? AppSemanticColors.darkSurfaceElevated
            : AppSemanticColors.ink,
        labelStyle: textTheme.labelMedium,
        shape: const StadiumBorder(),
        side: BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}
