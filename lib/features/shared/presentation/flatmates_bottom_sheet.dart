import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'paper/paper_edge_border.dart';
import 'paper/paper_surface.dart';

/// Shared bottom sheet: a paper-2 sheet with a torn top edge and an e3
/// shadow (DESIGN.md §8).
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

  /// Shows a modal bottom sheet on the paper treatment.
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    // The keyboard inset sits outside the height cap, so the sheet keeps its
    // full usable height above the keyboard instead of shrinking inside it.
    final maxHeight = (MediaQuery.sizeOf(context).height - bottomInset) * 0.9;

    return AnimatedPadding(
      duration: AppMotion.durationOrZero(context, AppMotion.bottomSheet),
      curve: AppMotion.easeOutQuart,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: PaperSurface(
          elevation: PaperElevation.e3,
          edge: PaperEdge.torn,
          borderRadius: BorderRadius.zero,
          padding: const EdgeInsets.only(
            left: AppSpacing.screen,
            right: AppSpacing.screen,
            top: AppSpacing.sm,
            bottom: AppSpacing.lg,
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
                  borderRadius: AppRadius.pillBorder,
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
