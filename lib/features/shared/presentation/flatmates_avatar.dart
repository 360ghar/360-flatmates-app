import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'flatmates_network_image.dart';

String initialsFromName(String? name) {
  final raw = name?.trim();
  if (raw == null || raw.isEmpty) {
    return 'FM';
  }
  final parts = raw
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'FM';
  }
  if (parts.length == 1) {
    return parts.first
        .substring(0, (parts.first.length < 2) ? parts.first.length : 2)
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

/// Deterministic pastel pair for initials avatars (Profile/Settings language).
///
/// Stable per [name] so the same person always gets the same colors.
({Color background, Color foreground}) avatarPaletteForName(
  String? name, {
  Brightness brightness = Brightness.light,
}) {
  final isDark = brightness == Brightness.dark;
  // (light bg, light fg, dark bg, dark fg)
  const palettes = <(Color, Color, Color, Color)>[
    (
      AppSemanticColors.blueSoft,
      AppSemanticColors.blueInk,
      AppSemanticColors.blueSoftDark,
      AppSemanticColors.blueMid,
    ),
    (
      AppSemanticColors.pinkSoft,
      AppSemanticColors.pinkInk,
      AppSemanticColors.pinkSoftDark,
      AppSemanticColors.pinkMid,
    ),
    (
      AppSemanticColors.tealSoft,
      AppSemanticColors.tealInk,
      AppSemanticColors.tealSoftDark,
      AppSemanticColors.tealMid,
    ),
    (
      AppSemanticColors.purpleSoft,
      AppSemanticColors.purpleInk,
      AppSemanticColors.purpleSoftDark,
      AppSemanticColors.purpleMid,
    ),
    (
      AppSemanticColors.greenSoft,
      AppSemanticColors.greenInk,
      AppSemanticColors.greenSoftDark,
      AppSemanticColors.greenMid,
    ),
    (
      AppSemanticColors.orangeSoft,
      AppSemanticColors.orangeInk,
      AppSemanticColors.orangeSoftDark,
      AppSemanticColors.orangeMid,
    ),
    (
      AppSemanticColors.yellowSoft,
      AppSemanticColors.yellowInk,
      AppSemanticColors.yellowSoftDark,
      AppSemanticColors.yellowMid,
    ),
  ];

  final key = name?.trim() ?? '';
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  final pair = palettes[hash % palettes.length];
  return (
    background: isDark ? pair.$3 : pair.$1,
    foreground: isDark ? pair.$4 : pair.$2,
  );
}

class FlatmatesAvatar extends StatefulWidget {
  const FlatmatesAvatar({
    required this.name,
    super.key,
    this.imageUrl,
    this.size = 52,
    this.showRing = false,
    this.onTap,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.tapLabel,
  });

  final String? name;
  final String? imageUrl;
  final double size;
  final bool showRing;
  final VoidCallback? onTap;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  /// Screen-reader name of the [onTap] action (for example "Add photo").
  final String? tapLabel;

  @override
  State<FlatmatesAvatar> createState() => _FlatmatesAvatarState();
}

class _FlatmatesAvatarState extends State<FlatmatesAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: AppMotion.compatibilityRing,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.showRing) return;
    // Under reduce motion the ring is drawn complete at once.
    if (AppMotion.reduceMotion(context)) {
      _ringController.value = 1;
    } else if (_ringController.isDismissed) {
      _ringController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant FlatmatesAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showRing && !oldWidget.showRing) {
      if (AppMotion.reduceMotion(context)) {
        _ringController.value = 1;
      } else {
        _ringController.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = initialsFromName(widget.name);
    final hasImage =
        widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty;
    final isCircle = widget.shape == BoxShape.circle;
    final resolvedRadius = isCircle
        ? null
        : (widget.borderRadius ?? AppRadius.mdBorder);
    final brightness = Theme.of(context).brightness;
    final palette = avatarPaletteForName(widget.name, brightness: brightness);

    final avatar = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: widget.shape,
        borderRadius: resolvedRadius,
        color: hasImage
            ? AppSemanticColors.paperDeepFor(brightness)
            : palette.background,
      ),
      child: hasImage
          ? (isCircle
                ? ClipOval(
                    child: FlatmatesNetworkImage(
                      imageUrl: widget.imageUrl!,
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                    ),
                  )
                : ClipRRect(
                    borderRadius: resolvedRadius!,
                    child: FlatmatesNetworkImage(
                      imageUrl: widget.imageUrl!,
                      width: widget.size,
                      height: widget.size,
                      fit: BoxFit.cover,
                    ),
                  ))
          : _AvatarFallback(
              initials: initials,
              size: widget.size,
              foreground: palette.foreground,
            ),
    );

    Widget avatarContent = avatar;

    if (widget.showRing) {
      avatarContent = AnimatedBuilder(
        animation: _ringController,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: _ringController.value,
              color: AppSemanticColors.clayFor(brightness),
              strokeWidth: 2.5,
              isCircle: isCircle,
              borderRadiusValue: resolvedRadius != null
                  ? resolvedRadius.topLeft.x
                  : AppRadius.md,
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: avatar,
        ),
      );
    }

    if (widget.onTap != null) {
      avatarContent = Semantics(
        button: true,
        label: widget.tapLabel,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: avatarContent,
        ),
      );
    }

    return avatarContent;
  }
}

/// Animated ring that draws around the avatar on mount.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.isCircle = true,
    this.borderRadiusValue = AppRadius.md,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final bool isCircle;
  final double borderRadiusValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (isCircle) {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = (size.shortestSide / 2) - (strokeWidth / 2);
      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        paint,
      );
    } else {
      final rect = Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      );
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(borderRadiusValue),
      );
      final path = Path()..addRRect(rrect);
      final pathMetrics = path.computeMetrics().toList();
      if (pathMetrics.isNotEmpty) {
        final metric = pathMetrics.first;
        final extractPath = metric.extractPath(0.0, metric.length * progress);
        canvas.drawPath(extractPath, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      isCircle != oldDelegate.isCircle ||
      borderRadiusValue != oldDelegate.borderRadiusValue;
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.initials,
    required this.size,
    required this.foreground,
  });

  final String initials;
  final double size;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      // Sized to the fixed circle, so it does not follow the text scale.
      child: Text(
        initials,
        textScaler: TextScaler.noScaling,
        style: theme.textTheme.titleMedium?.copyWith(
          color: foreground,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
