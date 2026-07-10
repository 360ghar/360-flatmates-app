import 'dart:math' as math show pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import '../../shared/presentation/profile_sections.dart';
import '../application/chat_actions_controller.dart';
import '../chats_repository.dart';
import '../domain/chat_report_reason.dart';
import 'widgets/chat_dialogs.dart';
import 'widgets/chat_property_card.dart';

/// Full profile of the other user in a conversation, opened by tapping the
/// peer header on the chat thread. Renders instantly from the conversation's
/// lightweight [ChatPeer] data and enriches with the full profile fetched
/// from the backend (bio, lifestyle preferences).
class ChatPeerProfilePage extends ConsumerWidget {
  const ChatPeerProfilePage({
    required this.userId,
    this.conversation,
    super.key,
  });

  final int userId;
  final ConversationSummaryModel? conversation;

  Future<void> _handleCall(BuildContext context, String? phone) async {
    final locale = AppLocalizations.of(context);
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (context.mounted) {
      FlatmatesToast.info(context, locale.phoneNotAvailable);
    }
  }

  Future<void> _handleReport(
    BuildContext context,
    WidgetRef ref,
    int peerId,
  ) async {
    final controller = ref.read(chatActionsControllerProvider);
    await ChatDialogs.showReportDialog(
      context: context,
      peerId: peerId,
      reasons: ChatReportReason.defaults(),
      controller: controller,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final brightness = theme.brightness;
    final profileAsync = ref.watch(peerProfileProvider(userId));
    final profile = profileAsync.valueOrNull;
    final compatAsync = ref.watch(peerCompatibilityProvider(userId));
    final compatResult = compatAsync.valueOrNull;
    final peer = conversation?.peer;

    final name =
        profile?['full_name'] as String? ?? peer?.fullName ?? locale.chatsTitle;
    final imageUrl =
        profile?['profile_image_url'] as String? ?? peer?.profileImageUrl;
    final age = (profile?['age'] as num?)?.toInt() ?? peer?.age;
    final profession = profile?['profession'] as String? ?? peer?.profession;
    final city = profile?['city'] as String? ?? peer?.city;
    final localityValue = profile?['locality'] as String? ?? peer?.locality;
    final matchPercentage =
        (profile?['match_percentage'] as num?)?.toDouble() ??
        peer?.matchPercentage;
    final bio = (profile?['bio'] as String?)?.trim();
    final phone = peer?.phoneNumber;
    final contextProperty = conversation?.contextProperty;

    final matchColor = matchPercentage != null
        ? _matchColor(brightness, matchPercentage)
        : AppSemanticColors.success;

    final locationParts = [
      if (localityValue != null && localityValue.trim().isNotEmpty)
        localityValue.trim(),
      if (city != null && city.trim().isNotEmpty) city.trim(),
    ];
    final ageProfessionParts = [
      if (age != null) locale.yearsOldLabel(age),
      if (profession != null && profession.trim().isNotEmpty) profession.trim(),
    ];

    final actionButtons = <Widget>[
      _ActionButton(
        icon: Icons.chat_bubble_outline_rounded,
        label: locale.messageCta,
        color: _ActionButtonColor.blue,
        onTap: () => context.pop(),
      ),
      _ActionButton(
        icon: Icons.call_outlined,
        label: locale.callCta,
        color: _ActionButtonColor.green,
        onTap: phone != null && phone.isNotEmpty
            ? () => _handleCall(context, phone)
            : null,
      ),
      if (contextProperty != null && conversation != null)
        _ActionButton(
          icon: Icons.event_available_outlined,
          label: locale.scheduleVisitCta,
          onTap: () => context.push(
            '/schedule-visit?conversationId=${conversation!.id}',
            extra: conversation!,
          ),
        ),
      _ActionButton(
        icon: Icons.flag_outlined,
        label: locale.reportCta,
        color: _ActionButtonColor.red,
        onTap: () => _handleReport(context, ref, userId),
      ),
    ];

    return FlatmatesScreen(
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl + AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            children: [
              // -- Avatar with progress ring --
              _AvatarWithRing(
                name: name,
                imageUrl: imageUrl,
                matchPercentage: matchPercentage,
                matchColor: matchColor,
              ),
              const SizedBox(height: AppSpacing.sm),
              // -- Name --
              Text(
                name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              // -- Age · Profession --
              if (ageProfessionParts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  ageProfessionParts.join(' · '),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(brightness),
                  ),
                ),
              ],
              // -- Location --
              if (locationParts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppSemanticColors.textSecondaryFor(brightness),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      locationParts.join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(brightness),
                      ),
                    ),
                  ],
                ),
              ],
              // -- Action buttons (icon-over-label) --
              if (actionButtons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: actionButtons
                      .map(
                        (b) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxs,
                            ),
                            child: b,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              // -- Listing details --
              if (contextProperty != null && conversation != null) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(label: locale.listingDetails),
                const SizedBox(height: AppSpacing.sm),
                ChatPropertyCard(
                  conversation: conversation!,
                  onTap: () =>
                      context.push('/flat-details/${contextProperty.id}'),
                ),
              ],

              // -- About --
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(label: locale.aboutLabel),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    bio,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: AppSemanticColors.textSecondaryFor(brightness),
                    ),
                  ),
                ),
              ],

              // -- Lifestyle --
              ..._lifestyleSection(locale, profile),

              // -- Preferences --
              ...[
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(label: locale.preferencesLabel),
                const SizedBox(height: AppSpacing.sm),
                PreferencesCard(
                  rows: [
                    if (profile?['gender_preference'] != null &&
                        (profile!['gender_preference'] as String)
                            .trim()
                            .isNotEmpty)
                      (
                        icon: Icons.person_outline_rounded,
                        label: locale.genderPreferenceLabel,
                        value: () {
                          final pref = (profile['gender_preference'] as String)
                              .trim()
                              .toLowerCase();
                          return pref == 'any'
                              ? locale.genderAny
                              : localizedFlatmatesGenderLabel(locale, pref);
                        }(),
                      ),
                    (
                      icon: Icons.pets_outlined,
                      label: locale.petsLabel,
                      value: (profile?['has_pets'] as bool?) == true
                          ? locale.quizHavePets
                          : locale.quizNoPets,
                    ),
                  ],
                ),
              ],

              // -- Compatibility breakdown --
              if (compatResult != null) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(label: locale.compatibilityBreakdown),
                const SizedBox(height: AppSpacing.sm),
                CompatBreakdownSection(result: compatResult),
              ],

              // -- Loading skeleton --
              if (profileAsync.isLoading && profile == null) ...[
                const SizedBox(height: AppSpacing.xl),
                const FlatmatesSkeleton.list(itemCount: 3),
              ],
            ],
          ),

          // -- Floating back button --
          Positioned(
            top: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: FlatmatesChromeIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
                tooltip: 'Back',
                style: FlatmatesChromeIconStyle.overlay,
              ),
            ),
          ),

          // -- Match % top-right --
          if (matchPercentage != null)
            Positioned(
              top: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppSemanticColors.canvas,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.elevation,
                  ),
                  child: Text(
                    '${matchPercentage.round()}% Match',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: matchColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _lifestyleGroups = <String, List<String>>{
    'Routine': ['sleep_schedule', 'cleanliness'],
    'Diet': ['food_habits'],
    'Habits': ['smoking_drinking', 'guests_policy'],
    'Work': ['work_style'],
  };

  /// Maps field key → raw value → descriptive display label.
  /// Avoids ambiguity where the same raw value (e.g. "flexible", "minimal")
  /// appears in different fields with different meanings.
  static const _valueLabels = <String, Map<String, String>>{
    'sleep_schedule': {
      'early_bird': 'Early riser',
      'flexible': 'Flexible schedule',
      'night_owl': 'Night owl',
    },
    'cleanliness': {
      'minimal': 'Minimal cleaning',
      'tidy': 'Keeps tidy',
      'spotless': 'Very clean',
    },
    'food_habits': {
      'vegetarian': 'Vegetarian',
      'vegan': 'Vegan',
      'non_vegetarian': 'Non-vegetarian',
      'eggetarian': 'Eggetarian',
      'no_preference': 'No dietary preference',
    },
    'smoking_drinking': {
      'neither': 'No smoking/drinking',
      'smoke_outside': 'Smokes outside only',
      'drink_occasionally': 'Drinks occasionally',
      'both_fine': 'Smoking & drinking OK',
    },
    'guests_policy': {
      'no_overnight_guests': 'No overnight guests',
      'occasional_ok': 'Guests occasionally OK',
      'open_house': 'Guests always welcome',
    },
    'work_style': {
      'wfh': 'Works from home',
      'office': 'Works from office',
      'hybrid': 'Hybrid work',
    },
  };

  List<Widget> _lifestyleSection(
    AppLocalizations locale,
    Map<String, dynamic>? profile,
  ) {
    final cells = <LifestyleCell>[];
    for (final group in _lifestyleGroups.entries) {
      for (final key in group.value) {
        final raw = profile?[key] as String?;
        if (raw != null && raw.isNotEmpty) {
          cells.add((
            icon: _fieldIcons[key] ?? Icons.circle_outlined,
            dim: _dimLabel(locale, key),
            value: _valueLabels[key]?[raw] ?? _humanize(raw),
          ));
        }
      }
    }
    if (cells.isEmpty) return [];

    return [
      const SizedBox(height: AppSpacing.lg),
      SectionHeader(label: locale.lifestyleSectionTitle),
      const SizedBox(height: AppSpacing.sm),
      LifestyleGrid(cells: cells),
    ];
  }

  static const _fieldIcons = <String, IconData>{
    'sleep_schedule': Icons.bedtime_outlined,
    'cleanliness': Icons.cleaning_services_outlined,
    'food_habits': Icons.restaurant_outlined,
    'smoking_drinking': Icons.local_bar_outlined,
    'guests_policy': Icons.groups_outlined,
    'work_style': Icons.work_outline_rounded,
  };

  static String _dimLabel(AppLocalizations locale, String key) {
    switch (key) {
      case 'sleep_schedule':
        return locale.lifestyleDimSleep;
      case 'cleanliness':
        return locale.lifestyleDimCleanliness;
      case 'food_habits':
        return locale.lifestyleDimFood;
      case 'smoking_drinking':
        return locale.lifestyleDimSmoking;
      case 'guests_policy':
        return locale.lifestyleDimGuests;
      case 'work_style':
        return locale.lifestyleDimWork;
      default:
        return _humanize(key);
    }
  }

  static String _humanize(String value) {
    final words = value.replaceAll('_', ' ').trim();
    if (words.isEmpty) return words;
    return words[0].toUpperCase() + words.substring(1);
  }

  Color _matchColor(Brightness brightness, double pct) {
    if (pct >= 70) return AppSemanticColors.success;
    if (pct >= 40) return AppSemanticColors.warning;
    if (pct > 0) return AppSemanticColors.error;
    return AppSemanticColors.textSecondaryFor(brightness);
  }
}

enum _ActionButtonColor { blue, green, pink, red }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.color = _ActionButtonColor.pink,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final _ActionButtonColor color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final enabled = onTap != null;
    final isDark = brightness == Brightness.dark;

    if (!enabled) {
      final disabledFg = AppSemanticColors.textTertiaryFor(brightness);
      return Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: const BoxDecoration(borderRadius: AppRadius.smBorder),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: disabledFg),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.microLabelSize,
                  fontWeight: FontWeight.w600,
                  color: disabledFg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final bg = switch (color) {
      _ActionButtonColor.blue =>
        isDark ? AppSemanticColors.blueSoftDark : AppSemanticColors.blueSoft,
      _ActionButtonColor.green =>
        isDark ? AppSemanticColors.greenSoftDark : AppSemanticColors.greenSoft,
      _ActionButtonColor.pink =>
        isDark ? AppSemanticColors.pinkSoftDark : AppSemanticColors.pinkSoft,
      _ActionButtonColor.red =>
        isDark ? AppSemanticColors.errorSoftDark : AppSemanticColors.errorBg,
    };
    final fg = switch (color) {
      _ActionButtonColor.blue => AppSemanticColors.blueInk,
      _ActionButtonColor.green => AppSemanticColors.greenInk,
      _ActionButtonColor.pink => AppSemanticColors.pinkInk,
      _ActionButtonColor.red => AppSemanticColors.error,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.smBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.smBorder,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.microLabelSize,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarWithRing extends StatelessWidget {
  const _AvatarWithRing({
    required this.name,
    required this.imageUrl,
    this.matchPercentage,
    required this.matchColor,
  });

  static const double _avatarSize = 128;
  static const double _ringSize = _avatarSize + 8;

  final String name;
  final String? imageUrl;
  final double? matchPercentage;
  final Color matchColor;

  @override
  Widget build(BuildContext context) {
    if (matchPercentage == null) {
      return FlatmatesAvatar(name: name, imageUrl: imageUrl, size: _avatarSize);
    }

    final progress = (matchPercentage! / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: _ringSize,
      height: _ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(_ringSize, _ringSize),
            painter: _AvatarRingPainter(
              progress: progress,
              color: matchColor,
              strokeWidth: 4,
              backgroundColor: matchColor.withValues(alpha: 0.15),
            ),
          ),
          FlatmatesAvatar(name: name, imageUrl: imageUrl, size: _avatarSize),
        ],
      ),
    );
  }
}

class _AvatarRingPainter extends CustomPainter {
  const _AvatarRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
