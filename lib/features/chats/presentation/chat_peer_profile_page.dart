import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/compatibility/compatibility_ring.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../shared/presentation/components.dart';
import '../chats_repository.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final profileAsync = ref.watch(peerProfileProvider(userId));
    final profile = profileAsync.valueOrNull;
    final peer = conversation?.peer;

    final name =
        profile?['full_name'] as String? ?? peer?.fullName ?? locale.chatsTitle;
    final imageUrl =
        profile?['profile_image_url'] as String? ?? peer?.profileImageUrl;
    final mode = profile?['mode'] as String? ?? peer?.mode;
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

    final locationParts = [
      if (localityValue != null && localityValue.trim().isNotEmpty)
        localityValue.trim(),
      if (city != null && city.trim().isNotEmpty) city.trim(),
    ];
    final ageProfessionParts = [
      if (age != null) locale.yearsOldLabel(age),
      if (profession != null && profession.trim().isNotEmpty) profession.trim(),
    ];

    return FlatmatesScreen(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => context.pop(),
          tooltip: locale.backCta,
        ),
        title: Text(name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        children: [
          // -- Header: avatar, name, mode, demographics, location, match --
          Column(
            children: [
              FlatmatesAvatar(name: name, imageUrl: imageUrl, size: 80),
              const SizedBox(height: AppSpacing.md),
              Text(
                name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: AppTypography.displayLgWeight,
                ),
              ),
              if (mode != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _ModeBadge(label: localizedFlatmatesModeLabel(locale, mode)),
              ],
              if (ageProfessionParts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  ageProfessionParts.join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  ),
                ),
              ],
              if (locationParts.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppSemanticColors.textSecondaryFor(
                        theme.brightness,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      locationParts.join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (matchPercentage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                CompatibilityRing(
                  percentage: matchPercentage,
                  size: 88,
                  strokeWidth: 6,
                  newLabel: locale.newMatch,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  locale.percentMatch(matchPercentage.round()),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: AppTypography.titleMdWeight,
                    color: _matchColor(theme.brightness, matchPercentage),
                  ),
                ),
              ],
            ],
          ),

          // -- Actions --
          if (conversation != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: FlatmatesButton.secondary(
                    key: const Key('peer_profile_call'),
                    label: locale.callCta,
                    icon: Icons.call_outlined,
                    onPressed: () => _handleCall(context, phone),
                  ),
                ),
                if (contextProperty != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FlatmatesButton(
                      key: const Key('peer_profile_schedule_visit'),
                      label: locale.scheduleVisitCta,
                      icon: Icons.event_available_outlined,
                      onPressed: () => context.push(
                        '/schedule-visit?conversationId=${conversation!.id}',
                        extra: conversation,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          // -- Property context --
          if (contextProperty != null && conversation != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(label: locale.listingDetails),
            ChatPropertyCard(
              conversation: conversation!,
              onViewListing: () =>
                  context.push('/flat-details/${contextProperty.id}'),
              onMiniCardTap: () =>
                  context.push('/flat-details/${contextProperty.id}'),
            ),
          ],

          // -- About --
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            _SectionHeader(label: locale.aboutLabel),
            FlatmatesCard(
              margin: EdgeInsets.zero,
              child: Text(
                bio,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
          ],

          // -- Lifestyle preferences --
          ..._lifestyleSection(theme, locale, profile),

          if (profileAsync.isLoading && profile == null) ...[
            const SizedBox(height: AppSpacing.xl),
            // Inline enrichment skeleton (not the bottom-sheet chrome).
            const FlatmatesSkeleton.list(itemCount: 3),
          ],
        ],
      ),
    );
  }

  List<Widget> _lifestyleSection(
    ThemeData theme,
    AppLocalizations locale,
    Map<String, dynamic>? profile,
  ) {
    const lifestyleKeys = [
      'sleep_schedule',
      'cleanliness',
      'food_habits',
      'smoking_drinking',
      'guests_policy',
      'work_style',
    ];
    final values = [
      for (final key in lifestyleKeys)
        if (profile?[key] is String && (profile![key] as String).isNotEmpty)
          profile[key] as String,
    ];
    if (values.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.xl),
      _SectionHeader(label: locale.lifestyleQuizTitle),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final value in values) FlatmatesChip(label: _humanize(value)),
        ],
      ),
    ];
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: AppTypography.titleMdWeight,
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppSemanticColors.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: AppTypography.captionSize,
          fontWeight: FontWeight.w600,
          color: AppSemanticColors.accent,
        ),
      ),
    );
  }
}
