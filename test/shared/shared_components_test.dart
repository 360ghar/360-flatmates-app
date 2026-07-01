import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_availability_pill.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_listing_meta_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AvailabilityPill.resolve', () {
    Future<AvailabilityVariant?> resolveVariant(
      WidgetTester tester, {
      required String? status,
      required DateTime? availableFrom,
      bool isAvailable = false,
    }) async {
      AvailabilityVariant? result;
      await tester.pumpWidget(
        testableWidget(
          child: Builder(
            builder: (context) {
              final pill = AvailabilityPill.resolve(
                context: context,
                status: status,
                availableFrom: availableFrom,
                isAvailable: isAvailable,
              );
              result = pill?.variant;
              return Scaffold(body: Text(pill?.label ?? 'none'));
            },
          ),
        ),
      );
      await tester.pump();
      return result;
    }

    testWidgets('returns underReview for pending_review status', (
      tester,
    ) async {
      final variant = await resolveVariant(
        tester,
        status: 'pending_review',
        availableFrom: null,
      );
      expect(variant, AvailabilityVariant.underReview);
    });

    testWidgets('returns underReview for under_review status', (tester) async {
      final variant = await resolveVariant(
        tester,
        status: 'under_review',
        availableFrom: null,
      );
      expect(variant, AvailabilityVariant.underReview);
    });

    testWidgets('returns available when availableFrom is in the past', (
      tester,
    ) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final variant = await resolveVariant(
        tester,
        status: 'active',
        availableFrom: yesterday,
      );
      expect(variant, AvailabilityVariant.available);
    });

    testWidgets('returns fromDate when availableFrom is in the future', (
      tester,
    ) async {
      final tomorrow = DateTime.now().add(const Duration(days: 10));
      final variant = await resolveVariant(
        tester,
        status: 'active',
        availableFrom: tomorrow,
      );
      expect(variant, AvailabilityVariant.fromDate);
    });

    testWidgets('returns null when nothing meaningful to surface', (
      tester,
    ) async {
      final variant = await resolveVariant(
        tester,
        status: 'active',
        availableFrom: null,
      );
      expect(variant, isNull);
    });
  });

  group('FlatmatesListingMetaChips', () {
    testWidgets('renders nothing when items is empty', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const MaterialApp(
            home: Scaffold(body: FlatmatesListingMetaChips(items: [])),
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('renders each item label', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const MaterialApp(
            home: Scaffold(
              body: FlatmatesListingMetaChips(
                items: [
                  ListingMetaItem(icon: Icons.bed_outlined, label: '2 Beds'),
                  ListingMetaItem(
                    icon: Icons.bathtub_outlined,
                    label: '1 Bath',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('2 Beds'), findsOneWidget);
      expect(find.text('1 Bath'), findsOneWidget);
    });
  });

  group('AvailabilityPill rendering', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const MaterialApp(
            home: Scaffold(
              body: AvailabilityPill(
                variant: AvailabilityVariant.available,
                label: 'Available now',
                color: AppSemanticColors.success,
                icon: Icons.check_circle_rounded,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Available now'), findsOneWidget);
    });
  });
}
