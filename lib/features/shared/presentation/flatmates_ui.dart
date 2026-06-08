import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/compatibility/compatibility_engine.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
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

class FlatmatesAvatar extends StatefulWidget {
  const FlatmatesAvatar({
    required this.name,
    super.key,
    this.imageUrl,
    this.size = 52,
    this.showRing = false,
    this.onTap,
  });

  final String? name;
  final String? imageUrl;
  final double size;
  final bool showRing;
  final VoidCallback? onTap;

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
    if (widget.showRing) {
      _ringController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant FlatmatesAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showRing && !oldWidget.showRing) {
      _ringController.forward(from: 0);
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

    final avatar = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppSemanticColors.accent.withValues(alpha: 0.95),
            AppSemanticColors.accent.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppSemanticColors.accent.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasImage
          ? ClipOval(
              child: FlatmatesNetworkImage(
                imageUrl: widget.imageUrl!,
                fit: BoxFit.cover,
              ),
            )
          : _AvatarFallback(initials: initials, size: widget.size),
    );

    Widget avatarContent = avatar;

    if (widget.showRing) {
      avatarContent = AnimatedBuilder(
        animation: _ringController,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: _ringController.value,
              color: AppSemanticColors.accent,
              strokeWidth: 2.5,
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
      avatarContent = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: avatarContent,
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
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - (strokeWidth / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Brand logo: "36" + rotate_right icon (acts as the "0") + "FLATMATES".
///
/// This is intentional per DESIGN.md — the rotate_right icon visually
/// represents the "0" in "360", making the logo read as "360 FLATMATES".
/// Do NOT change "36" to "360" or replace the icon with a literal "0".
class FlatmatesLogo extends StatelessWidget {
  const FlatmatesLogo({super.key, this.compact = false, this.centered = false});

  final bool compact;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numberSize = compact ? 28.0 : 38.0;
    final labelSize = compact ? 13.0 : 15.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '36',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: numberSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                ),
              ),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Transform.translate(
                  offset: Offset(0, compact ? -2 : -4),
                  child: Icon(
                    Icons.rotate_right_rounded,
                    color: AppSemanticColors.accent,
                    size: compact ? 30 : 38,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          'FLATMATES',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppSemanticColors.accent,
            fontSize: labelSize,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Button variant — determines visual style.
enum FlatmatesButtonVariant {
  /// Solid primary fill.
  primary,

  /// Outline with primary border.
  secondary,

  /// Text only, primary color.
  tertiary,

  /// Circular icon-only.
  iconOnly,

  /// Google theme button.
  google,
}

/// Primary CTA button — solid fill with premium press feedback.
///
/// Use named constructors for variants:
/// - [FlatmatesButton] (default) — solid primary
/// - [FlatmatesButton.secondary] — outline
/// - [FlatmatesButton.tertiary] — text only
/// - [FlatmatesButton.icon] — circular icon-only
class FlatmatesButton extends StatefulWidget {
  const FlatmatesButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 52,
    this.fullWidth = false,
  }) : variant = FlatmatesButtonVariant.primary,
       iconOnly = false,
       destructive = false;

  const FlatmatesButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 52,
    this.fullWidth = false,
    this.destructive = false,
  }) : variant = FlatmatesButtonVariant.secondary,
       iconOnly = false;

  const FlatmatesButton.tertiary({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.destructive = false,
  }) : variant = FlatmatesButtonVariant.tertiary,
       height = 44,
       fullWidth = false,
       iconOnly = false;

  const FlatmatesButton.icon({
    required this.onPressed,
    required this.icon,
    super.key,
    this.destructive = false,
  }) : variant = FlatmatesButtonVariant.iconOnly,
       label = '',
       height = 44,
       fullWidth = false,
       iconOnly = true;

  const FlatmatesButton.google({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 52,
    this.fullWidth = false,
  }) : variant = FlatmatesButtonVariant.google,
       destructive = false,
       iconOnly = false;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool fullWidth;
  final FlatmatesButtonVariant variant;
  final bool iconOnly;
  final bool destructive;

  @override
  State<FlatmatesButton> createState() => _FlatmatesButtonState();
}

class _FlatmatesButtonState extends State<FlatmatesButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onPressed != null;

    if (widget.iconOnly) {
      return _buildIconButton(theme, enabled);
    }

    switch (widget.variant) {
      case FlatmatesButtonVariant.primary:
        return _buildPrimary(theme, enabled);
      case FlatmatesButtonVariant.secondary:
        return _buildSecondary(theme, enabled);
      case FlatmatesButtonVariant.tertiary:
        return _buildTertiary(theme, enabled);
      case FlatmatesButtonVariant.iconOnly:
        return _buildIconButton(theme, enabled);
      case FlatmatesButtonVariant.google:
        return _buildGoogle(theme, enabled);
    }
  }

  Widget _buildPrimary(ThemeData theme, bool enabled) {
    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.buttonPress,
        curve: AppMotion.easeOutCubic,
        child: SizedBox(
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          child: FilledButton(
            onPressed: widget.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: widget.destructive
                  ? AppSemanticColors.error
                  : enabled
                  ? AppSemanticColors.accent
                  : null,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              elevation: enabled ? 1 : 0,
              shadowColor: enabled && !widget.destructive
                  ? AppSemanticColors.accent.withValues(alpha: 0.18)
                  : null,
            ),
            child: _buildChild(theme, Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondary(ThemeData theme, bool enabled) {
    final borderColor = widget.destructive
        ? AppSemanticColors.error
        : AppSemanticColors.accent;
    final textColor = widget.destructive
        ? AppSemanticColors.error
        : AppSemanticColors.accent;

    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.buttonPress,
        curve: AppMotion.easeOutCubic,
        child: SizedBox(
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: widget.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(
                color: _pressed
                    ? borderColor.withValues(alpha: 0.7)
                    : borderColor,
                width: 1.5,
              ),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
            ),
            child: _buildChild(theme, textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildTertiary(ThemeData theme, bool enabled) {
    final textColor = widget.destructive
        ? AppSemanticColors.error
        : AppSemanticColors.accent;

    return TextButton(
      onPressed: widget.onPressed,
      style: TextButton.styleFrom(foregroundColor: textColor),
      child: _buildChild(theme, textColor),
    );
  }

  Widget _buildIconButton(ThemeData theme, bool enabled) {
    final color = widget.destructive
        ? AppSemanticColors.error
        : AppSemanticColors.accent;

    return SizedBox(
      width: widget.height,
      height: widget.height,
      child: IconButton(
        onPressed: widget.onPressed,
        icon: Icon(widget.icon, size: 22),
        style: IconButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.1),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
    );
  }

  Widget _buildGoogle(ThemeData theme, bool enabled) {
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF131314) : const Color(0xFFFFFFFF);
    final foregroundColor = isDark ? const Color(0xFFE3E3E3) : const Color(0xFF3C4043);
    final borderColor = isDark ? const Color(0xFF8E918F) : const Color(0xFFDADCE0);
    final hoverColor = isDark ? const Color(0xFF1E1F20) : const Color(0xFFF8F9FA);

    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: AppMotion.buttonPress,
        curve: AppMotion.easeOutCubic,
        child: SizedBox(
          height: widget.height,
          width: widget.fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: enabled ? 1 : 0,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdBorder,
                side: BorderSide(
                  color: enabled ? borderColor : theme.disabledColor.withValues(alpha: 0.2),
                ),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
                  return hoverColor;
                }
                return null;
              }),
            ),
            child: Row(
              mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/google_logo.png',
                  width: 20,
                  height: 20,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: foregroundColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(ThemeData theme, Color textColor) {
    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 20),
          const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.variant == FlatmatesButtonVariant.primary
                  ? null
                  : textColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Legacy alias — now delegates to solid FlatmatesButton.
/// Prefer using FlatmatesButton directly in new code.
class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FlatmatesButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      height: height,
    );
  }
}

class FlatmatesSectionHeader extends StatelessWidget {
  const FlatmatesSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppSemanticColors.accent,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({
    required this.label,
    super.key,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = highlighted
        ? (isDark
              ? AppSemanticColors.coralSoftDark
              : AppSemanticColors.accentSoft)
        : (isDark
              ? AppSemanticColors.darkSurfaceElevated
              : AppSemanticColors.paper2);
    final foreground = highlighted
        ? AppSemanticColors.accent
        : (isDark ? AppSemanticColors.paper3 : AppSemanticColors.ink2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted
              ? AppSemanticColors.accent.withValues(alpha: 0.15)
              : AppSemanticColors.line.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standardized menu row for Profile and Settings screens.
/// Matches screenshot #15 / #19 menu item pattern.
class FlatmatesMenuItem extends StatefulWidget {
  const FlatmatesMenuItem({
    required this.label,
    required this.icon,
    super.key,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  State<FlatmatesMenuItem> createState() => _FlatmatesMenuItemState();
}

class _FlatmatesMenuItemState extends State<FlatmatesMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _menuIconPalette(widget.icon, widget.isDestructive, theme);
    final textColor = widget.isDestructive ? AppSemanticColors.error : null;

    return Listener(
      onPointerDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onPointerUp: widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      onPointerCancel: widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppSemanticColors.accent.withValues(alpha: 0.05),
        highlightColor: AppSemanticColors.accent.withValues(alpha: 0.03),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: AppMotion.buttonPress,
          curve: AppMotion.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                AnimatedOpacity(
                  opacity: _pressed ? 0.8 : 1.0,
                  duration: AppMotion.fast,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: palette.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppSemanticColors.ink3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

_MenuIconPalette _menuIconPalette(
  IconData icon,
  bool isDestructive,
  ThemeData theme,
) {
  final isDark = theme.brightness == Brightness.dark;
  if (isDestructive) {
    return _MenuIconPalette(
      background: isDark
          ? AppSemanticColors.errorSoftDark
          : AppSemanticColors.errorSoft,
      foreground: AppSemanticColors.error,
    );
  }

  Color soft;
  Color darkSoft;
  Color mid;
  if (icon == Icons.calendar_month_outlined ||
      icon == Icons.calendar_month ||
      icon == Icons.event_available_outlined) {
    soft = AppSemanticColors.tealSoft;
    darkSoft = AppSemanticColors.tealSoftDark;
    mid = AppSemanticColors.tealMid;
  } else if (icon == Icons.favorite_border ||
      icon == Icons.favorite_rounded ||
      icon == Icons.favorite_outline) {
    soft = AppSemanticColors.pinkSoft;
    darkSoft = AppSemanticColors.pinkSoftDark;
    mid = AppSemanticColors.pinkMid;
  } else if (icon == Icons.chat_bubble_outline ||
      icon == Icons.chat_bubble_rounded ||
      icon == Icons.message_outlined) {
    soft = AppSemanticColors.blueSoft;
    darkSoft = AppSemanticColors.blueSoftDark;
    mid = AppSemanticColors.blueMid;
  } else if (icon == Icons.description_outlined ||
      icon == Icons.article_outlined ||
      icon == Icons.assignment_outlined) {
    soft = AppSemanticColors.yellowSoft;
    darkSoft = AppSemanticColors.yellowSoftDark;
    mid = AppSemanticColors.yellowMid;
  } else if (icon == Icons.payment_outlined ||
      icon == Icons.account_balance_wallet_outlined ||
      icon == Icons.wallet_outlined) {
    soft = AppSemanticColors.greenSoft;
    darkSoft = AppSemanticColors.greenSoftDark;
    mid = AppSemanticColors.greenMid;
  } else if (icon == Icons.settings_outlined ||
      icon == Icons.tune ||
      icon == Icons.lock_outline ||
      icon == Icons.privacy_tip_outlined) {
    soft = AppSemanticColors.purpleSoft;
    darkSoft = AppSemanticColors.purpleSoftDark;
    mid = AppSemanticColors.purpleMid;
  } else if (icon == Icons.help_outline ||
      icon == Icons.support_agent_outlined ||
      icon == Icons.headset_mic_outlined) {
    soft = AppSemanticColors.orangeSoft;
    darkSoft = AppSemanticColors.orangeSoftDark;
    mid = AppSemanticColors.orangeMid;
  } else {
    soft = AppSemanticColors.coralSoft;
    darkSoft = AppSemanticColors.coralSoftDark;
    mid = AppSemanticColors.accent;
  }

  return _MenuIconPalette(
    background: isDark ? darkSoft : soft,
    foreground: mid,
  );
}

class _MenuIconPalette {
  const _MenuIconPalette({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

/// Notification list item card — matches screenshot #17 pattern.
/// Unread items get a left accent border + dot indicator.
class FlatmatesNotificationCard extends StatelessWidget {
  const FlatmatesNotificationCard({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    super.key,
    this.isRead = false,
    this.onTap,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final bool isRead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: !isRead
            ? const Border(
                left: BorderSide(color: AppSemanticColors.accent, width: 3),
              )
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: AppSpacing.edgeLg,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      time,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppSemanticColors.ink3,
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppSemanticColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile grid card for Likes tab — matches screenshot #9 2-column grid pattern.
/// Includes animated compatibility ring on mount.
class FlatmatesProfileGridCard extends StatefulWidget {
  const FlatmatesProfileGridCard({
    required this.name,
    required this.location,
    required this.profession,
    required this.matchPercentage,
    required this.imageUrl,
    required this.onMatchTap,
    required this.matchButtonLabel,
    super.key,
    this.age,
    this.blurImage = false,
  });

  final String name;
  final int? age;
  final String location;
  final String profession;
  final double? matchPercentage;
  final String? imageUrl;
  final VoidCallback? onMatchTap;
  final String matchButtonLabel;
  final bool blurImage;

  @override
  State<FlatmatesProfileGridCard> createState() =>
      _FlatmatesProfileGridCardState();
}

class _FlatmatesProfileGridCardState extends State<FlatmatesProfileGridCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: AppMotion.compatibilityRing,
    );
    _ringController.forward();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasReliableMatch =
        widget.matchPercentage != null && widget.matchPercentage! > 0;
    final matchColor = hasReliableMatch
        ? compatibilityScoreColor(widget.matchPercentage!)
        : AppSemanticColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: widget.blurImage ? 7 : 0,
                        sigmaY: widget.blurImage ? 7 : 0,
                      ),
                      child: FlatmatesNetworkImage(
                        imageUrl: widget.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppSemanticColors.accent.withValues(alpha: 0.18),
                            AppSemanticColors.secondarySurfaceFor(
                              theme.brightness,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              initialsFromName(widget.name),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: AppSemanticColors.accent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              AppLocalizations.of(context).photoPendingLabel,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppSemanticColors.textSecondaryFor(
                                  theme.brightness,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (widget.matchPercentage != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _MatchRingPainter(
                              progress: _ringController.value,
                              color: matchColor,
                              strokeWidth: 3,
                            ),
                            child: child,
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppSemanticColors.surfaceFor(
                              theme.brightness,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            hasReliableMatch
                                ? '${widget.matchPercentage!.toInt()}%'
                                : 'New',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: matchColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.age == null ? widget.name : '${widget.name}, ${widget.age}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.location.trim().isNotEmpty)
          Text(
            widget.location,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (widget.profession.trim().isNotEmpty)
          Text(
            widget.profession,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (widget.matchButtonLabel.isNotEmpty) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: FilledButton(
              onPressed: widget.onMatchTap,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.matchButtonLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Animated ring painter for the match percentage circle.
class _MatchRingPainter extends CustomPainter {
  _MatchRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - (strokeWidth / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_MatchRingPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// ── Localization helpers ────────────────────────────────────────────────

String localizedFlatmatesModeLabel(AppLocalizations locale, String mode) {
  switch (mode.trim().toLowerCase()) {
    case 'room_poster':
      return locale.modeRoomPoster;
    case 'seeker':
      return locale.modeSeeker;
    case 'co_hunter':
      return locale.modeCoHunter;
    case 'open_to_both':
      return locale.modeOpenToBoth;
    default:
      return humanizeFlatmatesToken(mode);
  }
}

String localizedFlatmatesGenderLabel(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'any':
      return locale.genderAny;
    case 'male':
      return locale.genderMale;
    case 'female':
      return locale.genderFemale;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesSharingTypeLabel(
  AppLocalizations locale,
  String value,
) {
  switch (value.trim().toLowerCase()) {
    case 'private_room':
      return locale.sharingPrivateRoom;
    case 'shared_room':
      return locale.sharingSharedRoom;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesVisitStatusLabel(
  AppLocalizations locale,
  String value,
) {
  switch (value.trim().toLowerCase()) {
    case 'scheduled':
      return locale.visitStatusScheduled;
    case 'confirmed':
      return locale.visitStatusConfirmed;
    case 'completed':
      return locale.visitStatusCompleted;
    case 'cancelled':
    case 'canceled':
      return locale.visitStatusCancelled;
    case 'requested':
      return locale.visitStatusRequested;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String localizedFlatmatesFeatureLabel(AppLocalizations locale, String value) {
  switch (value.trim().toLowerCase()) {
    case 'furnished':
      return locale.featureFurnished;
    case 'semi_furnished':
      return locale.featureSemiFurnished;
    case 'wifi':
    case 'wi_fi':
    case 'wi-fi':
    case 'high_speed_wifi':
    case 'fast_wifi':
      return locale.featureWifi;
    case 'balcony':
      return locale.featureBalcony;
    case 'attached_bathroom':
      return locale.featureAttachedBathroom;
    case 'parking':
      return locale.featureParking;
    case 'ac':
    case 'air_conditioning':
      return locale.featureAc;
    case 'washing_machine':
      return locale.featureWashingMachine;
    default:
      return humanizeFlatmatesToken(value);
  }
}

String humanizeFlatmatesToken(String value) {
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

/// Formats a distance in kilometers to a localized human-readable string.
///
/// Examples: "500m away", "2.5km away", "15km away"
String formatDistanceText(AppLocalizations locale, double? distanceKm) {
  if (distanceKm == null) return '';
  if (distanceKm < 1) return locale.distanceMeters((distanceKm * 1000).round());
  if (distanceKm < 10) {
    return locale.distanceKmDecimal(distanceKm.toStringAsFixed(1));
  }
  return locale.distanceKm(distanceKm.round());
}
