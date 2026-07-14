import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/profile/presentation/widgets/profile_strength_card.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

void main() {
  group('ProfileStrengthCard', () {
    testWidgets('renders percentage when profile data is available', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: ProfileStrengthCard(percent: 70, onTap: () {})),
        ),
      );
      await tester.pumpAndSettle();

      // The percentage number should be rendered.
      expect(find.text('70'), findsOneWidget);
    });

    testWidgets('renders 0% for empty profile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: ProfileStrengthCard(percent: 0, onTap: () {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders 100% for complete profile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: ProfileStrengthCard(percent: 100, onTap: () {})),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ProfileStrengthCard(percent: 50, onTap: () => tapped = true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ProfileStrengthCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
