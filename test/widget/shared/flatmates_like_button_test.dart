import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/shared/presentation/flatmates_like_button.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

void main() {
  group('FlatmatesLikeButton', () {
    testWidgets('renders outlined heart when not liked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FlatmatesLikeButton(liked: false, onTap: () {})),
        ),
      );

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('renders filled heart when liked', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: FlatmatesLikeButton(liked: true, onTap: () {})),
        ),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FlatmatesLikeButton(liked: false, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(FlatmatesLikeButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('has correct semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FlatmatesLikeButton(
              liked: false,
              onTap: () {},
              tooltip: 'Save',
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Save'), findsOneWidget);
    });

    testWidgets('uses custom size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FlatmatesLikeButton(
              liked: false,
              onTap: () {},
              size: 40,
              iconSize: 24,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byIcon(Icons.favorite_border_rounded),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 40);
      expect(sizedBox.height, 40);
    });

    testWidgets('has a 48 dp tap target around a smaller disc', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: FlatmatesLikeButton(liked: false, onTap: () {}),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(FlatmatesLikeButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(find.bySemanticsLabel('Add to your likes'), findsOneWidget);
    });
  });
}
