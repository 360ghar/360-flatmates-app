import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../bootstrap/bootstrap_controller.dart';
import '../../../bootstrap/catalog_helpers.dart';
import '../../../../core/compatibility/compatibility_engine.dart';
import '../../../../core/compatibility/compatibility_ring.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../chats/application/chat_actions_controller.dart';
import '../../../chats/chats_repository.dart';
import '../../../chats/domain/chat_report_reason.dart';
import '../../../chats/presentation/widgets/chat_dialogs.dart';
import '../../../shared/presentation/lifestyle_labels.dart';
import '../../../chats/presentation/widgets/peer_profile_action_button.dart';
import '../../../shared/presentation/components.dart';
import '../../../shared/presentation/profile_sections.dart';

class OwnerProfileSheet extends ConsumerWidget {
  const OwnerProfileSheet({
    required this.ownerId,
    required this.listingOwnerName,
    required this.onSendMessage,
    required this.onScheduleVisit,
    super.key,
  });

  final int ownerId;
  final String listingOwnerName;
  final VoidCallback onSendMessage;
  final VoidCallback onScheduleVisit;

  static Future<void> show({
    required BuildContext context,
    required int ownerId,
    required String listingOwnerName,
    required VoidCallback onSendMessage,
    required VoidCallback onScheduleVisit,
  }) {
    return FlatmatesBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OwnerProfileSheet(
        ownerId: ownerId,
        listingOwnerName: listingOwnerName,
        onSendMessage: onSendMessage,
        onScheduleVisit: onScheduleVisit,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(peerProfileProvider(ownerId));
    final compatAsync = ref.watch(peerCompatibilityProvider(ownerId));

    Future<void> handleReport() async {
      final controller = ref.read(chatActionsControllerProvider);
      final bootstrap = ref.read(bootstrapControllerProvider).valueOrNull;
      final catalogOptions = bootstrap?.catalogOptions(
        'flatmates_report_reasons',
      );
      final reasons = (catalogOptions != null && catalogOptions.isNotEmpty)
          ? catalogOptions
                .map(
                  (opt) =>
                      ChatReportReason(value: opt.id, catalogLabel: opt.label),
                )
                .toList()
          : ChatReportReason.defaults();
      if (!context.mounted) return;
      await ChatDialogs.showReportDialog(
        context: context,
        peerId: ownerId,
        reasons: reasons,
        controller: controller,
      );
    }

    return profileAsync.when(
      loading: () => const FlatmatesSkeleton.peerProfileSheet(),
      error: (_, _) => _OwnerProfileBody(
        peerData: null,
        listingOwnerName: listingOwnerName,
        onSendMessage: onSendMessage,
        onScheduleVisit: onScheduleVisit,
        onReport: handleReport,
        showError: true,
      ),
      // A null payload is the actual failure path (fetchPeerProfile catches
      // errors and returns null rather than throwing), so treat it like an
      // error: show the "couldn't load" hint and suppress the misleading
      // 0% match ring.
      data: (peerData) => _OwnerProfileBody(
        peerData: peerData,
        listingOwnerName: listingOwnerName,
        onSendMessage: onSendMessage,
        onScheduleVisit: onScheduleVisit,
        onReport: handleReport,
        showError: peerData == null,
        compatResult: compatAsync.valueOrNull,
      ),
    );
  }
}

class _OwnerProfileBody extends StatelessWidget {
  const _OwnerProfileBody({
    required this.peerData,
    required this.listingOwnerName,
    required this.onSendMessage,
    required this.onScheduleVisit,
    this.onReport,
    this.showError = false,
    this.compatResult,
  });

  final Map<String, dynamic>? peerData;
  final String listingOwnerName;
  final VoidCallback onSendMessage;
  final VoidCallback onScheduleVisit;
  final VoidCallback? onReport;
  final bool showError;
  final CompatibilityResult? compatResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // listingOwnerName is canonical — it's the same owner_name the detail page
    // renders. peerData['full_name'] can diverge (stale cache, backend drift)
    // so it must never override it.
    final name = listingOwnerName;
    final imageUrl = peerData?['profile_image_url'] as String?;
    final mode = peerData?['mode'] as String?;
    final city = peerData?['city'] as String?;
    final age = peerData?['age'];
    final profession = peerData?['profession'] as String?;
    final phone = peerData?['phone_number'] as String?;
    final bio = peerData?['bio'] as String?;
    final matchPercentage =
        (peerData?['match_percentage'] as num?)?.toDouble() ?? 0;
    final budgetMin = (peerData?['budget_min'] as num?)?.toDouble();
    final budgetMax = (peerData?['budget_max'] as num?)?.toDouble();
    final moveIn = peerData?['move_in_timeline'] as String?;
    final nonNegotiables =
        (peerData?['non_negotiables'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const <String>[];

    final locationParts = [?peerData?['locality']?.toString(), ?city];

    // Quick-stat chips (budget range, move-in timeline) — only with peer data.
    final budgetLabel = budgetRangeText(locale, budgetMin, budgetMax);
    final quickStats = <Widget>[
      if (peerData != null && budgetLabel.isNotEmpty)
        FlatmatesChip(
          key: const ValueKey('budget_chip'),
          label: budgetLabel,
          variant: FlatmatesChipVariant.info,
        ),
      if (moveIn != null && moveIn.trim().isNotEmpty)
        FlatmatesChip(
          key: const ValueKey('movein_chip'),
          icon: Icons.event_outlined,
          label: humanizeFlatmatesToken(moveIn),
          variant: FlatmatesChipVariant.info,
        ),
    ];

    // Lifestyle cells — one per non-empty lifestyle token, using dim/value labels.
    final lifestyleCells = <LifestyleCell>[
      for (final entry in <(String?, IconData, String)>[
        (
          peerData?['food_habits'] as String?,
          Icons.restaurant_outlined,
          'food_habits',
        ),
        (_resolvedSmoking(peerData), Icons.smoking_rooms_outlined, 'smoking'),
        (_resolvedDrinking(peerData), Icons.local_bar_outlined, 'drinking'),
        (
          peerData?['guests_policy'] as String?,
          Icons.groups_outlined,
          'guests_policy',
        ),
        (
          peerData?['cleanliness'] as String?,
          Icons.cleaning_services_outlined,
          'cleanliness',
        ),
        (
          peerData?['sleep_schedule'] as String?,
          Icons.bedtime_outlined,
          'sleep_schedule',
        ),
        (
          peerData?['work_style'] as String?,
          Icons.work_outline_rounded,
          'work_style',
        ),
      ])
        if (entry.$1 != null && entry.$1!.trim().isNotEmpty)
          (
            icon: entry.$2,
            dim: lifestyleDimLabel(locale, entry.$3),
            value: lifestyleValueLabel(locale, entry.$3, entry.$1!),
          ),
    ];

    final hasBio = bio != null && bio.trim().isNotEmpty;
    final compatResultLocal = compatResult;

    final actionButtons = <Widget>[
      PeerActionButton(
        key: const ValueKey('owner_action_message'),
        icon: Icons.chat_bubble_outline_rounded,
        label: locale.messageCta,
        color: PeerActionButtonColor.blue,
        onTap: onSendMessage,
      ),
      PeerActionButton(
        key: const ValueKey('owner_action_call'),
        icon: Icons.call_outlined,
        label: locale.callCta,
        color: PeerActionButtonColor.green,
        onTap: phone != null && phone.isNotEmpty
            ? () => _launchCall(phone)
            : null,
      ),
      PeerActionButton(
        key: const ValueKey('owner_action_schedule'),
        icon: Icons.event_available_outlined,
        label: locale.scheduleVisitCta,
        // ignore: avoid_redundant_argument_values
        color: PeerActionButtonColor.pink,
        onTap: onScheduleVisit,
      ),
      PeerActionButton(
        key: const ValueKey('owner_action_report'),
        icon: Icons.flag_outlined,
        label: locale.reportCta,
        color: PeerActionButtonColor.red,
        onTap: onReport,
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          // ROW 1: Photo left, info right.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Avatar with ring + match % pill below.
              Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CompatibilityRing(
                        percentage: matchPercentage,
                        size: 96,
                        strokeWidth: 4,
                      ),
                      FlatmatesAvatar(name: name, imageUrl: imageUrl, size: 80),
                    ],
                  ),
                  if (!showError && matchPercentage > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _matchColor(
                          matchPercentage,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        locale.percentMatch(matchPercentage.round()),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _matchColor(matchPercentage),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              // RIGHT: Name + role badge, age, location.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (mode != null)
                          _ModeBadge(mode: mode, isDark: isDark),
                      ],
                    ),
                    if (showError) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        locale.couldNotLoadContent,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppSemanticColors.textTertiaryFor(
                            isDark ? Brightness.dark : Brightness.light,
                          ),
                        ),
                      ),
                    ],
                    if (age != null || profession != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          [
                            if (age != null) '$age years',
                            ?profession,
                          ].join(' · '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppSemanticColors.textSecondaryFor(
                              isDark ? Brightness.dark : Brightness.light,
                            ),
                          ),
                        ),
                      ),
                    if (locationParts.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppSemanticColors.textTertiaryFor(
                              isDark ? Brightness.dark : Brightness.light,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            locationParts.join(', '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppSemanticColors.textSecondaryFor(
                                isDark ? Brightness.dark : Brightness.light,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Chips (budget, move-in) sit below location — single line.
                    if (quickStats.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(spacing: AppSpacing.sm, children: quickStats),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // ROW 2: Action buttons row.
          if (actionButtons.isNotEmpty)
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

          // About / bio.
          if (hasBio) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(label: locale.aboutLabel),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppSemanticColors.secondarySurfaceFor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(
                  color: AppSemanticColors.hairlineFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
                  width: 0.5,
                ),
              ),
              child: Text(
                bio.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppSemanticColors.textSecondaryFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
                ),
              ),
            ),
          ],

          // Lifestyle 2-column grid.
          if (lifestyleCells.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(label: locale.lifestyleSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            LifestyleGrid(cells: lifestyleCells),
          ],

          // Preferences (gender preference, pets).
          if (peerData != null) ..._preferencesSection(locale, peerData!),

          // Compatibility breakdown.
          if (compatResultLocal != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(label: locale.compatibilityBreakdown),
            const SizedBox(height: AppSpacing.sm),
            CompatBreakdownSection(result: compatResultLocal),
          ],

          // Non-negotiables / deal-breakers.
          if (nonNegotiables.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(label: locale.dealBreakersSectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppSemanticColors.secondarySurfaceFor(
                  isDark ? Brightness.dark : Brightness.light,
                ),
                borderRadius: AppRadius.mdBorder,
                border: Border.all(
                  color: AppSemanticColors.hairlineFor(
                    isDark ? Brightness.dark : Brightness.light,
                  ),
                  width: 0.5,
                ),
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final n in nonNegotiables)
                    FlatmatesChip(
                      label: humanizeFlatmatesToken(n),
                      variant: FlatmatesChipVariant.info,
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Send message CTA
          SizedBox(
            width: double.infinity,
            child: FlatmatesButton(
              label: locale.contactCta,
              onPressed: onSendMessage,
              icon: Icons.send_rounded,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        debugPrint('OwnerProfileSheet._launchCall: launchUrl returned false');
      }
    } catch (e) {
      debugPrint('OwnerProfileSheet._launchCall: $e');
    }
  }

  List<Widget> _preferencesSection(
    AppLocalizations locale,
    Map<String, dynamic> profile,
  ) {
    final rows = <PreferenceRow>[];

    final genderPref = profile['gender_preference'] as String?;
    if (genderPref != null && genderPref.trim().isNotEmpty) {
      final pref = genderPref.trim().toLowerCase();
      rows.add((
        icon: Icons.person_outline_rounded,
        label: locale.genderPreferenceLabel,
        value: pref == 'any'
            ? locale.genderAny
            : localizedFlatmatesGenderLabel(locale, pref),
      ));
    }

    final hasPets = profile['has_pets'];
    if (hasPets is bool) {
      rows.add((
        icon: Icons.pets_outlined,
        label: locale.petsLabel,
        value: hasPets ? locale.quizHavePets : locale.quizNoPets,
      ));
    }

    if (rows.isEmpty) return [];

    return [
      const SizedBox(height: AppSpacing.lg),
      SectionHeader(label: locale.preferencesLabel),
      const SizedBox(height: AppSpacing.sm),
      PreferencesCard(rows: rows),
    ];
  }

  /// Split smoking value with legacy `smoking_drinking` fallback. The legacy
  /// `neither` value resolves to null (no cell rendered).
  static String? _resolvedSmoking(Map<String, dynamic>? peerData) {
    final direct = peerData?['smoking'] as String?;
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();
    return switch (peerData?['smoking_drinking']) {
      'smoke_outside' || 'both_fine' => 'regularly',
      _ => null,
    };
  }

  /// Split drinking value with legacy `smoking_drinking` fallback. The legacy
  /// `neither` value resolves to null (no cell rendered).
  static String? _resolvedDrinking(Map<String, dynamic>? peerData) {
    final direct = peerData?['drinking'] as String?;
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();
    return switch (peerData?['smoking_drinking']) {
      'drink_occasionally' => 'occasionally',
      // 'both_fine' resolves to occasional drinking, matching the web
      // onboarding-store migration (smoking 'regularly' + drinking
      // 'occasionally') so both surfaces agree on the legacy value.
      'both_fine' => 'occasionally',
      _ => null,
    };
  }

  Color _matchColor(double pct) {
    if (pct >= 70) return AppSemanticColors.success;
    if (pct >= 40) return AppSemanticColors.warning;
    if (pct > 0) return AppSemanticColors.error;
    return AppSemanticColors.textTertiaryFor(Brightness.light);
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode, required this.isDark});
  final String mode;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      'co_hunter' => 'Co-Hunter',
      'room_poster' => 'Room Poster',
      'open_to_both' => 'Open to Both',
      _ => mode,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppSemanticColors.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppSemanticColors.accent,
        ),
      ),
    );
  }
}
