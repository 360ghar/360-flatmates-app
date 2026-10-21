import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/listings/presentation/widgets/manage_listing_card.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

void main() {
  const listing = PropertyListing(
    id: 42,
    ownerId: 1,
    propertyType: 'flatmate',
    title: 'Modern 2BHK in Koramangala',
    description: 'A beautiful flat',
    city: 'Bangalore',
    state: 'Karnataka',
    locality: 'Koramangala',
    subLocality: '5th Block',
    latitude: 12.93,
    longitude: 77.62,
    monthlyRent: 24000,
    mainImageUrl: null,
    imageUrls: [],
    areaSqft: 1200,
    bedrooms: 2,
    bathrooms: 2,
    features: [],
    tags: [],
    ownerName: 'Test User',
    availableFrom: null,
    genderPreference: 'any',
    sharingType: 'private_room',
    interestCount: 10,
    viewCount: 3800,
    likeCount: 24,
    isAvailable: true,
    status: 'live',
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    String status = 'active',
    bool isPaused = false,
    void Function(int, bool)? onTogglePause,
    VoidCallback? onReview,
  }) async {
    final locale = lookupAppLocalizations(const Locale('en'));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ManageListingCard(
              listing: listing,
              status: status,
              isPaused: isPaused,
              onTogglePause: onTogglePause ?? (_, _) {},
              onShare: () {},
              onEdit: () {},
              onViewStats: () {},
              onReview: onReview ?? () {},
              onRenew: () {},
              theme: ThemeData.light(),
              locale: locale,
            ),
          ),
        ),
      ),
    );
  }

  group('ManageListingCard', () {
    testWidgets('renders listing title, rent, location', (tester) async {
      await pumpCard(tester);

      expect(find.text('Modern 2BHK in Koramangala'), findsOneWidget);
      // Rent is formatted as ₹24,000 / mo
      expect(find.textContaining('24,000'), findsOneWidget);
    });

    testWidgets('renders pause/resume toggle for active listing', (
      tester,
    ) async {
      final locale = lookupAppLocalizations(const Locale('en'));
      await pumpCard(tester);

      // The pause action label should be present for an active listing.
      expect(find.text(locale.pauseListingCta), findsOneWidget);
    });

    testWidgets('renders resume toggle for paused listing', (tester) async {
      final locale = lookupAppLocalizations(const Locale('en'));
      await pumpCard(tester, status: 'paused', isPaused: true);

      expect(find.text(locale.resumeAction), findsOneWidget);
    });

    testWidgets('a rejected listing opens the review page, never a pause', (
      tester,
    ) async {
      // The server answers 409 LISTING_STATUS_CONFLICT to a pause or resume of
      // a rejected listing, so the card does not offer one.
      final locale = lookupAppLocalizations(const Locale('en'));
      var toggles = 0;
      var reviews = 0;
      await pumpCard(
        tester,
        status: 'rejected',
        onTogglePause: (_, _) => toggles++,
        onReview: () => reviews++,
      );

      expect(find.text(locale.pauseListingCta), findsNothing);
      expect(find.text(locale.resumeAction), findsNothing);
      await tester.tap(find.text(locale.reviewAction));
      await tester.pump();

      expect(reviews, 1);
      expect(toggles, 0);
    });

    testWidgets('renders renew toggle for expired listing', (tester) async {
      final locale = lookupAppLocalizations(const Locale('en'));
      await pumpCard(tester, status: 'expired');

      expect(find.text(locale.renewAction), findsOneWidget);
    });
  });
}
