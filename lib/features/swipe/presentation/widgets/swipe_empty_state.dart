import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_empty_state.dart';

/// Reason why the swipe deck is empty, used to show contextual messaging.
enum SwipeEmptyReason {
  /// The API returned zero profiles.
  noProfiles,

  /// The API returned profiles but all were filtered out by self-exclusion
  /// or deal-breaker filtering.
  allFiltered,

  /// The user swiped through every card in the current deck.
  endOfDeck,
}

/// Empty state shown when there are no more profiles to swipe on.
///
/// Wraps [FlatmatesEmptyState] with contextual copy and icon based on
/// [reason], plus a refresh CTA wired to [onRefresh].
class SwipeEmptyState extends StatelessWidget {
  const SwipeEmptyState({
    required this.reason,
    required this.onRefresh,
    super.key,
  });

  /// Why the deck is empty.
  final SwipeEmptyReason reason;

  /// Called when the user taps the refresh CTA.
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return FlatmatesEmptyState(
      title: _title(locale),
      subtitle: _subtitle(locale),
      icon: _icon,
      ctaLabel: locale.refreshProfilesCta,
      onCtaTap: onRefresh,
    );
  }

  String _title(AppLocalizations locale) => switch (reason) {
        SwipeEmptyReason.noProfiles => locale.swipeEmptyNoProfilesTitle,
        SwipeEmptyReason.allFiltered => locale.swipeEmptyAllFilteredTitle,
        SwipeEmptyReason.endOfDeck => locale.swipeEmptyEndOfDeckTitle,
      };

  String _subtitle(AppLocalizations locale) => switch (reason) {
        SwipeEmptyReason.noProfiles => locale.swipeEmptyNoProfilesSubtitle,
        SwipeEmptyReason.allFiltered => locale.swipeEmptyAllFilteredSubtitle,
        SwipeEmptyReason.endOfDeck => locale.swipeEmptyEndOfDeckSubtitle,
      };

  IconData get _icon => switch (reason) {
        SwipeEmptyReason.noProfiles => Icons.explore_off_rounded,
        SwipeEmptyReason.allFiltered => Icons.filter_alt_off_rounded,
        SwipeEmptyReason.endOfDeck => Icons.favorite_border_rounded,
      };
}
