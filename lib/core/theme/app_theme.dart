// ignore: unnecessary_import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'paper_theme.dart';

abstract final class AppTheme {
  /// Builds the Paper Diorama Material 3 theme. See DESIGN.md.
  static ThemeData build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final primary = AppSemanticColors.clayFor(brightness);
    final onPrimary = AppSemanticColors.onClayFor(brightness);
    final sky = AppSemanticColors.skyFor(brightness);
    final paper1 = AppSemanticColors.paper1For(brightness);
    final surface = AppSemanticColors.paper2For(brightness);
    final paper3 = AppSemanticColors.paper3For(brightness);
    final textPrimary = AppSemanticColors.textPrimaryFor(brightness);
    final textSecondary = AppSemanticColors.textSecondaryFor(brightness);
    final textTertiary = AppSemanticColors.textTertiaryFor(brightness);
    final outline = AppSemanticColors.hairlineFor(brightness);
    final danger = AppSemanticColors.dangerFor(brightness);

    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppSemanticColors.clay,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: AppSemanticColors.coralSoftFor(brightness),
          onPrimaryContainer: textPrimary,
          secondary: AppSemanticColors.pineFor(brightness),
          onSecondary: isDark
              ? AppSemanticColors.darkOnClay
              : AppSemanticColors.onPine,
          secondaryContainer: AppSemanticColors.pineSoftFor(brightness),
          onSecondaryContainer: textPrimary,
          tertiary: AppSemanticColors.marigoldFor(brightness),
          surface: surface,
          surfaceContainerLowest: sky,
          surfaceContainerLow: paper1,
          surfaceContainer: paper1,
          surfaceContainerHigh: surface,
          surfaceContainerHighest: paper3,
          onSurface: textPrimary,
          onSurfaceVariant: textSecondary,
          outline: outline,
          outlineVariant: outline,
          error: danger,
          onError: isDark
              ? AppSemanticColors.darkOnClay
              : AppSemanticColors.onClay,
          surfaceTint: Colors.transparent,
          shadow: isDark
              ? Colors.black.withValues(alpha: 0.5)
              : AppSemanticColors.ink.withValues(alpha: 0.14),
        );

    TextStyle display(double size, double height) => TextStyle(
      fontFamily: AppTypography.displayFamily,
      fontWeight: AppTypography.displayWeight,
      fontSize: size,
      height: height,
      color: textPrimary,
    );

    TextStyle body({
      required double size,
      required double height,
      FontWeight weight = FontWeight.w400,
      Color? color,
    }) => TextStyle(
      fontWeight: weight,
      fontSize: size,
      height: height,
      color: color ?? textPrimary,
    );

    final textTheme = TextTheme(
      displayLarge: display(AppTypography.displaySize, 1.1),
      displayMedium: display(AppTypography.h1Size, AppTypography.h1Height),
      displaySmall: display(AppTypography.h2Size, AppTypography.h2Height),
      headlineLarge: display(AppTypography.h1Size, AppTypography.h1Height),
      headlineMedium: display(AppTypography.h2Size, AppTypography.h2Height),
      headlineSmall: display(AppTypography.h3Size, AppTypography.h3Height),
      titleLarge: body(
        size: AppTypography.titleSize,
        height: AppTypography.titleHeight,
        weight: AppTypography.titleWeight,
      ),
      titleMedium: body(
        size: 16,
        height: 1.25,
        weight: AppTypography.titleWeight,
      ),
      titleSmall: body(size: 15, height: 1.25, weight: FontWeight.w500),
      bodyLarge: body(
        size: AppTypography.bodySize,
        height: AppTypography.bodyHeight,
      ),
      bodyMedium: body(
        size: AppTypography.bodySmallSize,
        height: AppTypography.bodySmallHeight,
        color: textSecondary,
      ),
      bodySmall: body(
        size: AppTypography.captionSize,
        height: AppTypography.captionHeight,
        color: textTertiary,
      ),
      labelLarge: body(
        size: AppTypography.buttonMdSize,
        height: AppTypography.buttonMdHeight,
        weight: AppTypography.buttonMdWeight,
      ),
      labelMedium: body(
        size: AppTypography.labelSize,
        height: AppTypography.labelHeight,
        weight: AppTypography.labelWeight,
      ),
      labelSmall: body(
        size: AppTypography.badgeSize,
        height: AppTypography.badgeHeight,
        weight: AppTypography.badgeWeight,
        color: textSecondary,
      ),
    );

    const controlShape = RoundedRectangleBorder(
      borderRadius: AppRadius.mdBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: sky,
      canvasColor: sky,
      dividerColor: outline,
      textTheme: textTheme,
      extensions: [PaperTheme.of(brightness)],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: sky,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        toolbarHeight: 56,
        titleSpacing: AppSpacing.sm,
        titleTextStyle: display(AppTypography.h3Size, AppTypography.h3Height),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        actionsIconTheme: IconThemeData(color: textPrimary, size: 22),
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
        surfaceTintColor: Colors.transparent,
        titleTextStyle: display(AppTypography.h3Size, AppTypography.h3Height),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
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
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: danger, width: 2),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: danger),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.base,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(color: textTertiary),
        labelStyle: textTheme.labelMedium?.copyWith(color: textSecondary),
      ),
      // Paper tab strip: the active tab rises one layer (paper-2 on paper-1).
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paper1,
        indicatorColor: surface,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
        ),
        shadowColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : textTertiary,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return body(
            size: 12,
            height: 1.25,
            weight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primary : textTertiary,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppSemanticColors.paperDeepFor(brightness);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppSemanticColors.clayPressFor(brightness);
            }
            return primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? textTertiary
                : onPrimary,
          ),
          elevation: WidgetStateProperty.all(0),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(controlShape),
        ),
      ),
      // Secondary actions are a soft pine fill, never an outline next to a
      // filled button (DESIGN.md §8).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            AppSemanticColors.pineSoftFor(brightness),
          ),
          foregroundColor: WidgetStateProperty.all(textPrimary),
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          side: WidgetStateProperty.all(BorderSide.none),
          shape: WidgetStateProperty.all(controlShape),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(primary),
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: paper3,
        elevation: 0,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        actionTextColor: primary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppSemanticColors.coralSoftFor(brightness),
        labelStyle: textTheme.labelMedium,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        side: BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: AppSemanticColors.paperDeepFor(brightness),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        inactiveTrackColor: AppSemanticColors.paperDeepFor(brightness),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : AppSemanticColors.paperDeepFor(brightness),
        ),
        thumbColor: WidgetStateProperty.all(paper3),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
