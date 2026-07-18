import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/discover/discover_repository.dart';
import 'package:flatmates_app/features/discover/domain/property_listing.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/discover_listing_card.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

PropertyListing _listing({
  int id = 1,
  bool compact = false,
  String? mainImageUrl,
  double monthlyRent = 24000,
  double? securityDeposit,
}) => PropertyListing(
  id: id,
  ownerId: 100,
  propertyType: 'flatmate',
  title: 'Modern 2BHK in Koramangala',
  description: 'A beautiful flat',
  city: 'Bangalore',
  state: 'Karnataka',
  locality: 'Koramangala',
  subLocality: '5th Block',
  latitude: 12.9352,
  longitude: 77.6245,
  monthlyRent: monthlyRent,
  mainImageUrl: mainImageUrl,
  imageUrls: const [],
  areaSqft: 1200,
  bedrooms: 2,
  bathrooms: 2,
  features: const ['wifi', 'parking'],
  tags: const [],
  ownerName: 'Rahul',
  availableFrom: null,
  genderPreference: 'any',
  sharingType: 'private_room',
  interestCount: 10,
  viewCount: 3800,
  likeCount: 24,
  isAvailable: true,
  securityDeposit: securityDeposit,
);

void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: Center(child: child)),
  );

  group('DiscoverListingCard', () {
    testWidgets('compact listing card fits map carousel constraints', (
      tester,
    ) async {
      // The compact card uses a 16:10 aspect ratio (vs 1:1 for feed).
      // Verify it renders without overflow in a narrow carousel slot.
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 280,
            child: DiscoverListingCard(
              item: _listing(compact: true),
              compact: true,
              onLike: () {},
            ),
          ),
        ),
      );

      // Verify the card rendered.
      expect(find.byType(DiscoverListingCard), findsOneWidget);

      // The compact card should show the rent (formatted).
      expect(find.textContaining('24'), findsWidgets);

      // Verify the AspectRatio is 16/10 for compact mode.
      final aspectRatio = tester.widget<AspectRatio>(
        find.descendant(
          of: find.byType(DiscoverListingCard),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(aspectRatio.aspectRatio, 16 / 10);
    });

    testWidgets('feed card uses 1:1 aspect ratio', (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 280,
            child: DiscoverListingCard(item: _listing(), onLike: () {}),
          ),
        ),
      );

      final aspectRatio = tester.widget<AspectRatio>(
        find.descendant(
          of: find.byType(DiscoverListingCard),
          matching: find.byType(AspectRatio),
        ),
      );
      expect(aspectRatio.aspectRatio, 1.0);
    });

    testWidgets(
      'feed card shows full rent and move-in without mid-price ellipsis at half width',
      (tester) async {
        // Home grid is 2 columns (~160–180px). Old Row+Flexible layout
        // truncated rent mid-number (e.g. ₹68,7…). Assert full amount.
        FlutterErrorDetails? overflowError;
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed')) {
            overflowError = details;
          }
          previousOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = previousOnError);

        await tester.pumpWidget(
          wrap(
            SizedBox(
              width: 160,
              child: DiscoverListingCard(
                item: _listing(monthlyRent: 68700, securityDeposit: 100000),
                onLike: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Rent uses Text.rich; findRichText required. Move-in is plain Text.
        expect(
          find.textContaining('₹68,700', findRichText: true),
          findsWidgets,
        );
        expect(
          find.textContaining('/month', findRichText: true),
          findsOneWidget,
        );
        expect(find.textContaining('Move-in'), findsOneWidget);
        expect(find.textContaining('1,68,700'), findsOneWidget);
        // Ellipsis character must not appear on the price block.
        expect(find.textContaining('\u2026', findRichText: true), findsNothing);
        expect(overflowError, isNull);
      },
    );
  });
}
