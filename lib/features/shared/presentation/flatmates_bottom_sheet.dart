import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Shared bottom sheet — solid canvas, soft top radius, quiet drag handle.
///
/// Use [FlatmatesBottomSheet.show()] instead of raw [showModalBottomSheet].
class FlatmatesBottomSheet extends StatelessWidget {
  const FlatmatesBottomSheet({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.actions,
  });

  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;

  /// Shows a modal bottom sheet with Airbnb-aligned surface treatment.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
    String? subtitle,
    List<Widget>? actions,
    bool isScrollControlled = false,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      barrierColor: AppSemanticColors.scrim50,
      builder: (context) => FlatmatesBottomSheet(
        title: title,
        subtitle: subtitle,
        actions: actions,
        child: builder(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final sheetBg = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.canvas;

    return ClipRRect(
      borderRadius: AppRadius.sheetTopBorder,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: AppRadius.sheetTopBorder,
        ),
        child: AnimatedContainer(
          duration: AppMotion.bottomSheet,
          curve: AppMotion.easeOutQuart,
          padding: EdgeInsets.only(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            top: AppSpacing.md,
            bottom: bottomInset + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppSemanticColors.hairlineFor(theme.brightness),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header row
              if (title != null || actions != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title != null)
                              Text(
                                title!,
                                style: theme.textTheme.headlineSmall,
                              ),
                            if (subtitle != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                subtitle!,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                      ...?actions,
                    ],
                  ),
                ),
              // Content
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
