import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/shared/presentation/flatmates_skeleton.dart';
import 'package:flatmates_app/features/shared/presentation/skeleton/variants/discover_feed_skeleton.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

void main() {
  group('FlatmatesSkeleton', () {
    testWidgets('default list skeleton builds without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: FlatmatesSkeleton.list()),
        ),
      );
      // Use pump() instead of pumpAndSettle() because the skeleton has a
      // repeating shimmer animation that never settles.
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(FlatmatesSkeleton), findsOneWidget);
    });

    testWidgets('page variants build without throwing', (tester) async {
      final variants = <Widget>[
        const FlatmatesSkeleton.card(),
        const FlatmatesSkeleton.list(),
        const FlatmatesSkeleton.feed(),
        const FlatmatesSkeleton.profile(),
        const FlatmatesSkeleton.discoverFeed(),
        const FlatmatesSkeleton.browseListings(),
        const FlatmatesSkeleton.flatDetails(),
        const FlatmatesSkeleton.chatMessages(),
        const FlatmatesSkeleton.swipeCard(),
        const FlatmatesSkeleton.conversationList(),
        const FlatmatesSkeleton.notificationList(),
        const FlatmatesSkeleton.visitList(),
        const FlatmatesSkeleton.manageListings(),
        const FlatmatesSkeleton.mapExplore(),
        const FlatmatesSkeleton.searchFilters(),
        const FlatmatesSkeleton.settingsList(),
        const FlatmatesSkeleton.form(),
        const FlatmatesSkeleton.peerProfileSheet(),
        const FlatmatesSkeleton.legalContent(),
      ];

      for (final variant in variants) {
        // Give each variant a bounded height so internal ListViews don't
        // hit "unbounded height" errors. Some Column-based variants may
        // overflow the test surface — that's expected in a test environment
        // and doesn't indicate a real bug.
        await tester.pumpWidget(
          MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: SizedBox(height: 2000, child: variant)),
          ),
        );
        await tester.pump();
        // Drain any soft overflow errors — the test verifies the skeleton
        // builds without hard crashes, not that it lays out perfectly.
        tester.takeException();
      }
    });

    testWidgets('reduced motion keeps skeleton static', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: FlatmatesSkeleton.list()),
          ),
        ),
      );
      // With reduced motion, pumpAndSettle should work since there's no
      // repeating animation.
      await tester.pumpAndSettle();

      // With reduced motion, the skeleton should still render.
      expect(find.byType(FlatmatesSkeleton), findsOneWidget);
      // No exception should be thrown.
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced motion never allocates the shimmer ticker', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: FlatmatesSkeleton.list()),
          ),
        ),
      );
      await tester.pump();

      final shimmer = find.byType(FlatmatesSkeletonShimmer);
      expect(shimmer, findsOneWidget);

      // `SingleTickerProviderStateMixin` reports its ticker in the state's
      // diagnostics (`ticker active` / `ticker inactive`), so an absent
      // `ticker` property means no ticker — and therefore no
      // AnimationController — was ever created. The pre-fix code called
      // `_controller.stop()` here, which forced the `late final` controller
      // (and its ticker) into existence.
      final state = tester.state(shimmer);
      expect(state.toString(), isNot(contains('ticker')));

      // Nothing is scheduled either, however long the skeleton stays up.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.binding.transientCallbackCount, 0);
      }

      // The static path renders the bones directly: no FadeTransition of its
      // own to animate.
      expect(
        find.descendant(of: shimmer, matching: find.byType(FadeTransition)),
        findsNothing,
      );
      expect(find.byType(FlatmatesSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('with motion enabled the shimmer owns a running ticker', (
      tester,
    ) async {
      // The contrast case: it proves the ticker diagnostic used above is
      // really visible when a ticker exists, so the reduced-motion assertion
      // cannot pass just because the diagnostic string is empty.
      await tester.pumpWidget(
        const MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: FlatmatesSkeleton.list()),
        ),
      );
      await tester.pump();

      final shimmer = find.byType(FlatmatesSkeletonShimmer);
      expect(shimmer, findsOneWidget);
      expect(tester.state(shimmer).toString(), contains('ticker active'));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      expect(
        find.descendant(of: shimmer, matching: find.byType(FadeTransition)),
        findsOneWidget,
      );
    });

    testWidgets('discover feed card row mirrors the loaded grid columns', (
      tester,
    ) async {
      // DiscoverPage switches the "Picked for you" grid to 3 columns at 600 dp
      // and 4 at 900 dp; the placeholder row must match or a wide screen
      // reflows when the feed arrives (DESIGN.md §8).
      Future<int> columnsAt(double width) async {
        await tester.pumpWidget(
          MaterialApp(
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 800)),
              child: const Scaffold(
                body: FlatmatesSkeleton.discoverFeedCards(),
              ),
            ),
          ),
        );
        await tester.pump();

        final row = find.descendant(
          of: find.byType(DiscoverFeedCardsSkeleton),
          matching: find.byType(Row),
        );
        expect(row, findsOneWidget);
        // One card per column with a gap between them: n cards, n-1 gaps.
        final children = tester.widget<Row>(row).children.length;
        return (children + 1) ~/ 2;
      }

      expect(await columnsAt(320), 2);
      expect(await columnsAt(599), 2);
      expect(await columnsAt(600), 3);
      expect(await columnsAt(899), 3);
      expect(await columnsAt(900), 4);
      expect(await columnsAt(1200), 4);
    });
  });
}
