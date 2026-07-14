import 'package:flutter/material.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'flatmates_chrome_icon_button.dart';
import 'flatmates_ui.dart';

/// Standardized Airbnb-style screen header with back/title/actions/logo variants.
///
/// Replaces custom headers in notifications, settings, help, schedule visit,
/// create listing, search filters, etc.
///
/// Visual language (DESIGN.md):
/// - Canvas surface, zero elevation, 1px bottom hairline
/// - Circular outline chrome icon buttons for back/actions
/// - Left-aligned title at title-md (16/600)
enum FlatmatesHeaderVariant { backTitle, logo, titleOnly, titleAction }

class FlatmatesHeader extends StatelessWidget implements PreferredSizeWidget {
  const FlatmatesHeader({
    required this.variant,
    super.key,
    this.title,
    this.titleWidget,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.showHairline = true,
  }) : assert(
         variant != FlatmatesHeaderVariant.backTitle ||
             title != null ||
             titleWidget != null,
         'title or titleWidget is required for backTitle variant',
       );

  const FlatmatesHeader.backTitle({
    this.title,
    this.titleWidget,
    super.key,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.showHairline = true,
  }) : variant = FlatmatesHeaderVariant.backTitle,
       assert(
         title != null || titleWidget != null,
         'title or titleWidget is required for backTitle',
       );

  const FlatmatesHeader.logo({
    super.key,
    this.onBack,
    this.actions,
    this.title,
    this.titleWidget,
    this.centerTitle = false,
    this.showHairline = true,
  }) : variant = FlatmatesHeaderVariant.logo;

  const FlatmatesHeader.titleOnly({
    required this.title,
    super.key,
    this.onBack,
    this.actions,
    this.titleWidget,
    this.centerTitle = false,
    this.showHairline = true,
  }) : variant = FlatmatesHeaderVariant.titleOnly;

  const FlatmatesHeader.titleAction({
    required this.title,
    required this.actions,
    super.key,
    this.onBack,
    this.titleWidget,
    this.centerTitle = false,
    this.showHairline = true,
  }) : variant = FlatmatesHeaderVariant.titleAction;

  final FlatmatesHeaderVariant variant;
  final String? title;

  /// Optional custom title widget (e.g. search bar). Takes precedence over [title].
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showHairline;

  static const double toolbarHeight = 56;

  @override
  Size get preferredSize => const Size.fromHeight(toolbarHeight);

  bool get _showsBack =>
      variant == FlatmatesHeaderVariant.backTitle ||
      (variant == FlatmatesHeaderVariant.logo && onBack != null) ||
      (onBack != null && variant != FlatmatesHeaderVariant.logo);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hairline = AppSemanticColors.hairlineFor(brightness);
    final backTooltip = MaterialLocalizations.of(context).backButtonTooltip;

    final Widget? leading;
    if (_showsBack) {
      leading = Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: FlatmatesChromeIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: backTooltip,
          onPressed: onBack ?? () => Navigator.maybeOf(context)?.pop(),
        ),
      );
    } else if (variant == FlatmatesHeaderVariant.logo) {
      leading = const Padding(
        padding: EdgeInsets.only(left: AppSpacing.base),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FlatmatesLogo(toolbar: true),
        ),
      );
    } else {
      leading = null;
    }

    return AppBar(
      toolbarHeight: toolbarHeight,
      leadingWidth: _showsBack
          ? 56
          : (variant == FlatmatesHeaderVariant.logo ? 88 : null),
      leading: leading,
      automaticallyImplyLeading: false,
      title: titleWidget ?? _buildTitle(context),
      titleSpacing: _showsBack || variant == FlatmatesHeaderVariant.logo
          ? AppSpacing.sm
          : AppSpacing.base,
      centerTitle: centerTitle,
      actions: actions != null && actions!.isNotEmpty
          ? [...actions!, const SizedBox(width: AppSpacing.sm)]
          : null,
      shape: showHairline ? Border(bottom: BorderSide(color: hairline)) : null,
    );
  }

  Widget? _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    if (variant == FlatmatesHeaderVariant.logo) {
      // Logo lives in leading when no back; with back, show logo as title.
      if (onBack != null) {
        return const FlatmatesLogo(toolbar: true);
      }
      return null;
    }

    if (title == null || title!.trim().isEmpty) return null;

    final style = theme.textTheme.titleMedium?.copyWith(
      fontSize: AppTypography.titleMdSize,
      fontWeight: AppTypography.titleMdWeight,
      height: AppTypography.titleMdHeight,
      letterSpacing: AppTypography.titleMdLetterSpacing,
      color: AppSemanticColors.textPrimaryFor(theme.brightness),
    );

    return Text(
      title!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
