import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

/// One 48px premium search bar used everywhere.
///
/// Replaces all custom search bars across discover, help, location,
/// and search filters screens.
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

    return AnimatedScale(
      scale: _isFocused ? 1.01 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.easeOutCubic,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: AppRadius.smBorder,
          boxShadow: _isFocused
              ? [AppShadows.inputFocusGlow(AppSemanticColors.accent)]
              : const [],
        ),
        child: SizedBox(
          height: 48,
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? AppSemanticColors.paper
                  : AppSemanticColors.ink,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppSemanticColors.ink3,
              ),
              prefixIcon: Icon(
                widget.leadingIcon ?? Icons.search_rounded,
                size: 20,
                color: _isFocused
                    ? AppSemanticColors.accent
                    : AppSemanticColors.ink3,
              ),
              suffixIcon: widget.trailingIcon != null
                  ? IconButton(
                      icon: Icon(
                        widget.trailingIcon,
                        size: 20,
                        color: AppSemanticColors.ink3,
                      ),
                      onPressed: widget.onTrailingTap,
                      tooltip: widget.trailingTooltip,
                    )
                  : null,
              filled: true,
              fillColor: theme.brightness == Brightness.dark
                  ? AppSemanticColors.darkSurface.withValues(alpha: 0.5)
                  : AppSemanticColors.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              border: const OutlineInputBorder(
                borderRadius: AppRadius.smBorder,
                borderSide: BorderSide(color: AppSemanticColors.line),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: AppRadius.smBorder,
                borderSide: BorderSide(color: AppSemanticColors.line),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.smBorder,
                borderSide: BorderSide(
                  color: AppSemanticColors.accent,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
