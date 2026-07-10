import 'package:flatmates_app/features/shared/presentation/flatmates_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('default list skeleton exposes loading semantics', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const FlatmatesSkeleton.list()));
    expect(find.bySemanticsLabel('Loading'), findsWidgets);
    expect(find.byType(FlatmatesSkeleton), findsOneWidget);
  });

  testWidgets('page variants build without throwing', (tester) async {
    final variants = <MapEntry<String, Widget>>[
      const MapEntry('card', FlatmatesSkeleton.card()),
      const MapEntry('list', FlatmatesSkeleton.list(itemCount: 3)),
      const MapEntry('discoverFeed', FlatmatesSkeleton.discoverFeed()),
      const MapEntry(
        'browseListings',
        FlatmatesSkeleton.browseListings(itemCount: 2),
      ),
      const MapEntry('flatDetails', FlatmatesSkeleton.flatDetails()),
      const MapEntry(
        'chatMessages',
        FlatmatesSkeleton.chatMessages(itemCount: 2),
      ),
      const MapEntry('swipeCard', FlatmatesSkeleton.swipeCard()),
      const MapEntry(
        'conversationList',
        FlatmatesSkeleton.conversationList(itemCount: 2),
      ),
      const MapEntry(
        'notificationList',
        FlatmatesSkeleton.notificationList(itemCount: 2),
      ),
      const MapEntry('visitList', FlatmatesSkeleton.visitList(itemCount: 2)),
      const MapEntry(
        'manageListings',
        FlatmatesSkeleton.manageListings(itemCount: 1),
      ),
      const MapEntry('mapExplore', FlatmatesSkeleton.mapExplore()),
      const MapEntry('searchFilters', FlatmatesSkeleton.searchFilters()),
      const MapEntry(
        'settingsList',
        FlatmatesSkeleton.settingsList(itemCount: 2),
      ),
      const MapEntry('form', FlatmatesSkeleton.form(itemCount: 2)),
      const MapEntry('peerProfileSheet', FlatmatesSkeleton.peerProfileSheet()),
      const MapEntry('legalContent', FlatmatesSkeleton.legalContent()),
      const MapEntry('profile', FlatmatesSkeleton.profile()),
    ];

    for (final entry in variants) {
      await tester.pumpWidget(wrap(entry.value));
      // Drain layout so overflow errors surface as exceptions.
      await tester.pump();
      expect(tester.takeException(), isNull, reason: entry.key);
      expect(find.byType(FlatmatesSkeleton), findsOneWidget);
    }
  });

  testWidgets('reduced motion keeps skeleton static', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: wrap(const FlatmatesSkeleton.list(itemCount: 2)),
      ),
    );
    expect(find.byType(FlatmatesSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
    // No AnimationController-driven shimmer frames required.
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
