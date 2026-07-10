import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import 'components.dart';

/// Pill-shaped global search bar (Airbnb `search-bar-pill`).
///
/// White surface, fully rounded, hairline + single elevation tier.
/// No accent focus glow — quiet chrome.
class FlatmatesSearchBar extends StatefulWidget {
  const FlatmatesSearchBar({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.trailingTooltip,
    this.onTrailingTap,
    this.readOnly = false,
    this.autofocus = false,
  });

  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final String? trailingTooltip;
  final VoidCallback? onTrailingTap;
  final bool readOnly;
  final bool autofocus;

  @override
  State<FlatmatesSearchBar> createState() => _FlatmatesSearchBarState();
}

class _FlatmatesSearchBarState extends State<FlatmatesSearchBar> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_isFocused != _focusNode.hasFocus) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = AppSemanticColors.textPrimaryFor(theme.brightness);
    final muted = AppSemanticColors.textTertiaryFor(theme.brightness);
    final fill = isDark
        ? AppSemanticColors.darkSurface
        : AppSemanticColors.canvas;
    final hairline = AppSemanticColors.hairlineFor(theme.brightness);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: hairline),
        boxShadow: AppShadows.elevationFor(theme.brightness),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              style: theme.textTheme.bodyMedium?.copyWith(color: ink),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: muted),
                prefixIcon: Icon(
                  widget.leadingIcon ?? AppIcons.search,
                  size: 20,
                  color: muted,
                ),
                suffixIcon: widget.trailingIcon != null
                    ? IconButton(
                        icon: Icon(widget.trailingIcon, size: 20, color: muted),
                        onPressed: widget.onTrailingTap,
                        tooltip: widget.trailingTooltip,
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                  vertical: AppSpacing.md,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
