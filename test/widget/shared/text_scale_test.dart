import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/theme/app_theme.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_trust_badge.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

/// Regression tests for text that used to clip or overflow once the platform
/// text scale grew (1.3x is a common accessibility setting) or once a Hindi
/// string arrived that is longer than its English template.
///
/// These must run against the real [AppTheme] — the button and badge metrics
/// come from its text theme, so the stock Material theme measures differently.
Widget _scaled({
  required Widget child,
  double scale = 1.3,
  double width = 360,
}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: MaterialApp(
      theme: AppTheme.build(brightness: Brightness.light),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('FlatmatesTrustBadge label (finding 25)', () {
    testWidgets('ellipsizes instead of overflowing in a narrow bounded box', (
      tester,
    ) async {
      await tester.pumpWidget(
        _scaled(
          width: 160,
          child: const FlatmatesTrustBadge(
            label: 'Only you and Priyanka Venkataraman can see this note',
            variant: FlatmatesTrustBadgeVariant.privacy,
            compact: true,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final label = tester.widget<Text>(find.byType(Text));
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
    });

    testWidgets('lays out with no exception as the only child of a Row', (
      tester,
    ) async {
      // Row hands non-flex children unbounded main-axis constraints. The
      // badge's internal Flexible must therefore stay loose-fit inside a
      // MainAxisSize.min Row, or RenderFlex asserts "children have non-zero
      // flex but incoming width constraints are unbounded" — a red screen at
      // enter_phone_page.dart and chat_message_bubble.dart.
      await tester.pumpWidget(
        _scaled(
          child: const Row(children: [FlatmatesTrustBadge(label: 'Private')]),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Private'), findsOneWidget);
    });

    testWidgets('lays out with no exception beside a sibling Expanded', (
      tester,
    ) async {
      // Exact geometry of visit_card.dart: Expanded title + non-flex badge.
      await tester.pumpWidget(
        _scaled(
          child: const Row(
            children: [
              Expanded(child: Text('Visit to 2BHK in Indiranagar')),
              FlatmatesTrustBadge(label: 'Reschedule suggested', compact: true),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('FlatmatesProfileGridCard match button (finding 27)', () {
    // The likes grid reserves 52px below the square photo; the button plus its
    // 8px gap has to stay inside that at 1.0x and grow without clipping above.
    Widget gridTile({required double scale, String label = 'Match back'}) {
      return _scaled(
        scale: scale,
        child: SizedBox(
          width: 158,
          height: 158 + 52,
          child: FlatmatesProfileGridCard(
            name: 'Anjali Sharma',
            age: 26,
            location: 'Indiranagar, Bengaluru',
            profession: 'Product Designer',
            matchPercentage: 82,
            imageUrl: null,
            matchButtonLabel: label,
            onMatchTap: () {},
          ),
        ),
      );
    }

    testWidgets('keeps its 34px height at 1.0x text scale', (tester) async {
      await tester.pumpWidget(gridTile(scale: 1.0));

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(FilledButton)).height, 34);
    });

    testWidgets('grows instead of clipping the label at 1.3x text scale', (
      tester,
    ) async {
      await tester.pumpWidget(gridTile(scale: 1.3));

      expect(tester.takeException(), isNull);

      final buttonHeight = tester.getSize(find.byType(FilledButton)).height;
      final labelHeight = tester.getSize(find.text('Match back')).height;

      // The button must have grown past the old fixed 34 so the taller line
      // box (Devanagari matras included) is fully inside it.
      expect(buttonHeight, greaterThan(34));
      expect(buttonHeight, greaterThanOrEqualTo(labelHeight));
      // ...and still fit the grid's 52px below-photo reserve.
      expect(buttonHeight, lessThanOrEqualTo(52 - 8));
    });

    testWidgets('does not overflow with a long Hindi label at 1.3x', (
      tester,
    ) async {
      await tester.pumpWidget(gridTile(scale: 1.3, label: 'मैच करें'));

      expect(tester.takeException(), isNull);
      final label = tester.widget<Text>(find.text('मैच करें'));
      expect(label.maxLines, 1);
      expect(label.overflow, TextOverflow.ellipsis);
    });
  });
}
