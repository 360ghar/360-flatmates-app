import 'package:flatmates_app/features/listings/presentation/widgets/manage_listing_card.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('ManageListingCard exposes expiry and pause action', (
    tester,
  ) async {
    int? toggledListingId;
    bool? toggledPausedState;
    final listing = _ListingStub(
      expiresAt: DateTime.now().add(const Duration(days: 3)),
    );

    await tester.pumpWidget(
      testableWidget(
        child: Builder(
          builder: (context) {
            final locale = AppLocalizations.of(context);
            final theme = Theme.of(context);
            return Scaffold(
              body: SingleChildScrollView(
                child: ManageListingCard(
                  listing: listing,
                  status: 'active',
                  isPaused: false,
                  onTogglePause: (listingId, currentlyPaused) {
                    toggledListingId = listingId;
                    toggledPausedState = currentlyPaused;
                  },
                  onShare: () {},
                  onEdit: () {},
                  onViewStats: () {},
                  onReview: () {},
                  onRenew: () {},
                  theme: theme,
                  locale: locale,
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Expires in 3d'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.text('Pause'));

    expect(toggledListingId, 7);
    expect(toggledPausedState, isFalse);
  });
}

class _ListingStub {
  _ListingStub({this.expiresAt});

  final int id = 7;
  final String title = 'Test room';
  final String? mainImageUrl = null;
  final double? monthlyRent = 25000;
  final int? bedrooms = 2;
  final int? bathrooms = 2;
  final double? areaSqft = 900;
  final String? ownerName = 'Owner';
  final int? interestCount = 4;
  final int? viewCount = 12;
  final DateTime? expiresAt;
  final DateTime? availableFrom = null;
}
