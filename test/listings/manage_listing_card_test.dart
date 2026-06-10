import 'package:flatmates_app/features/discover/domain/property_listing.dart';
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
    final listing = PropertyListing(
      id: 7,
      ownerId: null,
      propertyType: null,
      title: 'Test room',
      description: null,
      city: null,
      state: null,
      locality: null,
      subLocality: null,
      latitude: null,
      longitude: null,
      monthlyRent: 25000,
      mainImageUrl: null,
      imageUrls: const [],
      areaSqft: 900,
      bedrooms: 2,
      bathrooms: 2,
      features: const [],
      tags: const [],
      ownerName: 'Owner',
      availableFrom: null,
      genderPreference: null,
      sharingType: null,
      interestCount: 4,
      viewCount: 12,
      likeCount: 0,
      isAvailable: true,
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
