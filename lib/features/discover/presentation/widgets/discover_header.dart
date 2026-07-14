import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../shared/presentation/flatmates_location_chip.dart';
import '../../../shared/presentation/flatmates_ui.dart';

class DiscoverHeader extends StatelessWidget {
  const DiscoverHeader({
    required this.greetingLabel,
    required this.name,
    required this.location,
    required this.avatarUrl,
    required this.userName,
    this.onAvatarTap,
    this.onLocationTap,
    super.key,
  });

  /// Max characters shown on the home location chip (full name opens in picker).
  static const int locationPreviewMaxChars = 15;

  /// Time-of-day label only, e.g. "Afternoon" / "Morning" / "Evening".
  final String greetingLabel;

  /// First name shown in brand pink after the greeting label.
  final String name;

  final String location;
  final String? avatarUrl;
  final String? userName;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLocationTap;

  /// Short label for the location chip; full [location] is still used by the picker.
  static String locationPreview(
    String location, {
    int maxChars = locationPreviewMaxChars,
  }) {
    final trimmed = location.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars)}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final ink = AppSemanticColors.textPrimaryFor(brightness);
    const brand = AppSemanticColors.primary;
    final previewLocation = locationPreview(location);

    final greetingStyle = theme.textTheme.titleMedium?.copyWith(
      color: ink,
      fontSize: AppTypography.displaySmSize,
      fontWeight: AppTypography.displaySmWeight,
      height: AppTypography.displaySmHeight,
      letterSpacing: AppTypography.displaySmLetterSpacing,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  style: greetingStyle,
                  children: [
                    TextSpan(text: '$greetingLabel, '),
                    TextSpan(
                      text: name,
                      style: greetingStyle?.copyWith(color: brand),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (previewLocation.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FlatmatesLocationChip(
                    locationName: previewLocation,
                    dense: true,
                    onTap: onLocationTap,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _InteractivePressScale(
          onTap: onAvatarTap,
          child: FlatmatesAvatar(name: userName, imageUrl: avatarUrl, size: 45),
        ),
      ],
    );
  }
}

/// Applies premium scale-down on press using Listener and AnimatedScale.
class _InteractivePressScale extends StatefulWidget {
  const _InteractivePressScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_InteractivePressScale> createState() => _InteractivePressScaleState();
}

class _InteractivePressScaleState extends State<_InteractivePressScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: AppMotion.buttonPress,
          curve: AppMotion.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}
