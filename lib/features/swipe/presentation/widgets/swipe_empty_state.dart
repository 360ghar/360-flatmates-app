import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/paper/paper_scene.dart';
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
      prop: _prop,
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

  /// DESIGN.md §6 props: magnifier when a search finds nothing, heart for
  /// the likes deck.
  PaperProp get _prop => switch (reason) {
    SwipeEmptyReason.noProfiles => PaperProp.magnifier,
    SwipeEmptyReason.allFiltered => PaperProp.magnifier,
    SwipeEmptyReason.endOfDeck => PaperProp.heart,
  };
}
