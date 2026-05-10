import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'flatmates_ui.dart';

/// Standardized screen header with back/title/actions/logo variants.
///
/// Replaces custom headers in notifications, settings, help, schedule visit,
/// create listing, search filters, etc.
enum FlatmatesHeaderVariant { backTitle, logo, titleOnly, titleAction }

class FlatmatesHeader extends StatelessWidget implements PreferredSizeWidget {
  const FlatmatesHeader({
    required this.variant,
    super.key,
    this.title,
    this.onBack,
    this.actions,
    this.centerTitle = false,
  }) : assert(
         variant != FlatmatesHeaderVariant.backTitle || title != null,
         'title is required for backTitle variant',
       );

  const FlatmatesHeader.backTitle({
    required String this.title,
    super.key,
    this.onBack,
    this.actions,
    this.centerTitle = false,
  }) : variant = FlatmatesHeaderVariant.backTitle;

  const FlatmatesHeader.logo({
    super.key,
    this.onBack,
    this.actions,
    this.title,
    this.centerTitle = false,
  }) : variant = FlatmatesHeaderVariant.logo;

  const FlatmatesHeader.titleOnly({
    required String this.title,
    super.key,
    this.onBack,
    this.actions,
    this.centerTitle = false,
  }) : variant = FlatmatesHeaderVariant.titleOnly;

  const FlatmatesHeader.titleAction({
    required String this.title,
    required this.actions,
    super.key,
    this.onBack,
    this.centerTitle = false,
  }) : variant = FlatmatesHeaderVariant.titleAction;

  final FlatmatesHeaderVariant variant;
  final String? title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading:
          variant == FlatmatesHeaderVariant.backTitle ||
              variant == FlatmatesHeaderVariant.logo && onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack ?? () => Navigator.maybeOf(context)?.pop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          : variant == FlatmatesHeaderVariant.logo
          ? const Padding(
              padding: EdgeInsets.only(left: AppSpacing.screen),
              child: FlatmatesLogo(compact: true),
            )
          : null,
      title: _buildTitle(context),
      centerTitle: centerTitle || variant == FlatmatesHeaderVariant.logo,
      actions: actions != null
          ? [...actions!, const SizedBox(width: AppSpacing.sm)]
          : null,
    );
  }

  Widget? _buildTitle(BuildContext context) {
    switch (variant) {
      case FlatmatesHeaderVariant.logo:
        return null;
      case FlatmatesHeaderVariant.backTitle:
      case FlatmatesHeaderVariant.titleOnly:
      case FlatmatesHeaderVariant.titleAction:
        return Text(title!);
    }
  }
}
