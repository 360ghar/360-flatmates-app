import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/shared/presentation/flatmates_availability_pill.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_listing_meta_chips.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

void main() {
  group('AvailabilityPill.resolve', () {
    testWidgets('returns underReview for pending_review status', (
      tester,
    ) async {
      AvailabilityPill? result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              result = AvailabilityPill.resolve(
                context: context,
                status: 'pending_review',
                availableFrom: null,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.variant, AvailabilityVariant.underReview);
    });

    testWidgets('returns underReview for under_review status', (tester) async {
      AvailabilityPill? result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              result = AvailabilityPill.resolve(
                context: context,
                status: 'under_review',
                availableFrom: null,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.variant, AvailabilityVariant.underReview);
    });

    testWidgets('returns available for past availableFrom date', (
      tester,
    ) async {
      AvailabilityPill? result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              result = AvailabilityPill.resolve(
                context: context,
                status: 'live',
                availableFrom: DateTime(2020),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.variant, AvailabilityVariant.available);
    });

    testWidgets('returns null when no status and no date', (tester) async {
      AvailabilityPill? result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              result = AvailabilityPill.resolve(
                context: context,
                status: null,
                availableFrom: null,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });

  group('FlatmatesListingMetaChips', () {
    testWidgets('renders each item label', (tester) async {
      final items = [
        const ListingMetaItem(icon: Icons.bed_outlined, label: '2 Beds'),
        const ListingMetaItem(icon: Icons.bathtub_outlined, label: '2 Baths'),
        const ListingMetaItem(
          icon: Icons.square_foot_outlined,
          label: '1200 sqft',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FlatmatesListingMetaChips(items: items)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 Beds'), findsOneWidget);
      expect(find.text('2 Baths'), findsOneWidget);
      expect(find.text('1200 sqft'), findsOneWidget);
    });

    testWidgets('renders nothing when items is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FlatmatesListingMetaChips(items: [])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FlatmatesListingMetaChips), findsOneWidget);
      // SizedBox.shrink() should be rendered.
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
