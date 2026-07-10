import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import '../../shared/presentation/profile_sections.dart';
import '../application/chat_actions_controller.dart';
import '../chats_repository.dart';
import '../domain/chat_report_reason.dart';
import 'widgets/chat_dialogs.dart';
import 'widgets/chat_property_card.dart';
import 'widgets/peer_profile_action_button.dart';
import 'widgets/peer_profile_avatar_ring.dart';

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
        compatResult?.percentage ??
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
      PeerActionButton(
        key: const ValueKey('peer_action_message'),
        icon: Icons.chat_bubble_outline_rounded,
        label: locale.messageCta,
        color: PeerActionButtonColor.blue,
        onTap: () => context.pop(),
      ),
      PeerActionButton(
        key: const ValueKey('peer_action_call'),
        icon: Icons.call_outlined,
        label: locale.callCta,
        color: PeerActionButtonColor.green,
        onTap: phone != null && phone.isNotEmpty
            ? () => _handleCall(context, phone)
            : null,
      ),
      if (contextProperty != null && conversation != null)
        PeerActionButton(
          key: const ValueKey('peer_action_visit'),
          icon: Icons.event_available_outlined,
          label: locale.scheduleVisitCta,
          onTap: () => context.push(
            '/schedule-visit?conversationId=${conversation!.id}',
            extra: conversation!,
          ),
        ),
      PeerActionButton(
        key: const ValueKey('peer_action_report'),
        icon: Icons.flag_outlined,
        label: locale.reportCta,
        color: PeerActionButtonColor.red,
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
              PeerProfileAvatarRing(
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

              // -- Preferences (only when profile is loaded) --
              if (profile != null) ...[..._preferencesSection(locale, profile)],

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
                tooltip: locale.backCta,
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
                    color: AppSemanticColors.surfaceFor(brightness),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppShadows.elevationFor(brightness),
                  ),
                  child: Text(
                    locale.percentMatch(matchPercentage.round()),
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
            value: _lifestyleValueLabel(locale, key, raw),
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

  /// Maps a lifestyle field key + raw value to a localized display label
  /// using the existing quiz ARB keys.
  static String _lifestyleValueLabel(
    AppLocalizations l,
    String key,
    String raw,
  ) => switch (key) {
    'sleep_schedule' => switch (raw) {
      'early_bird' => l.quizEarlyBird,
      'flexible' => l.quizFlexible,
      'night_owl' => l.quizNightOwl,
      _ => _humanize(raw),
    },
    'cleanliness' => switch (raw) {
      'minimal' => l.quizCleanMinimal,
      'tidy' => l.quizCleanTidy,
      'spotless' => l.quizCleanSpotless,
      _ => _humanize(raw),
    },
    'food_habits' => switch (raw) {
      'vegetarian' => l.quizVegetarian,
      'vegan' => l.quizVegan,
      'non_vegetarian' => l.quizNonVegetarian,
      'eggetarian' => l.quizEggetarian,
      'no_preference' => l.quizNoFoodPref,
      _ => _humanize(raw),
    },
    'smoking_drinking' => switch (raw) {
      'neither' => l.quizNeither,
      'smoke_outside' => l.quizSmokeOutside,
      'drink_occasionally' => l.quizDrinkOccasionally,
      'both_fine' => l.quizBothFine,
      _ => _humanize(raw),
    },
    'guests_policy' => switch (raw) {
      'no_overnight_guests' => l.quizNoGuests,
      'occasional_ok' => l.quizOccasionalGuests,
      'open_house' => l.quizOpenHouse,
      _ => _humanize(raw),
    },
    'work_style' => switch (raw) {
      'wfh' => l.quizWfh,
      'office' => l.quizOffice,
      'hybrid' => l.quizHybrid,
      _ => _humanize(raw),
    },
    _ => _humanize(raw),
  };

  List<Widget> _preferencesSection(
    AppLocalizations locale,
    Map<String, dynamic> profile,
  ) {
    final rows = <(IconData, String, String)>[];

    final genderPref = profile['gender_preference'] as String?;
    if (genderPref != null && genderPref.trim().isNotEmpty) {
      final pref = genderPref.trim().toLowerCase();
      rows.add((
        Icons.person_outline_rounded,
        locale.genderPreferenceLabel,
        pref == 'any'
            ? locale.genderAny
            : localizedFlatmatesGenderLabel(locale, pref),
      ));
    }

    // Only show pets row when the value is explicitly a boolean so we never
    // present "No pets" for an unknown/null state.
    final hasPets = profile['has_pets'];
    if (hasPets is bool) {
      rows.add((
        Icons.pets_outlined,
        locale.petsLabel,
        hasPets ? locale.quizHavePets : locale.quizNoPets,
      ));
    }

    if (rows.isEmpty) return [];

    return [
      const SizedBox(height: AppSpacing.lg),
      SectionHeader(label: locale.preferencesLabel),
      const SizedBox(height: AppSpacing.sm),
      PreferencesCard(
        rows: rows.map((r) => (icon: r.$1, label: r.$2, value: r.$3)).toList(),
      ),
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
