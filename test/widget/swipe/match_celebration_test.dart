import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_ui.dart';
import 'package:flatmates_app/features/swipe/match_celebration_screen.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

void main() {
  Widget wrap(MatchCelebrationScreen child) => MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  );

  group('MatchCelebrationScreen', () {
    testWidgets('renders match celebration with both names', (tester) async {
      await tester.pumpWidget(
        wrap(
          MatchCelebrationScreen(
            userName: 'Alice',
            userImageUrl: null,
            peerName: 'Bob',
            peerImageUrl: null,
            onOpenChat: () {},
            onKeepSwiping: () {},
          ),
        ),
      );

      // Pump past the scale animation. Use pump() instead of pumpAndSettle()
      // because the ConfettiWidget runs a continuous animation.
      await tester.pump(const Duration(seconds: 1));

      // The peer name appears in the "You and {peerName} liked each other" text.
      expect(find.textContaining('Bob'), findsOneWidget);

      // "Great Match!" heading should be present.
      expect(find.textContaining('Match'), findsOneWidget);

      // Both avatars should be rendered.
      expect(find.byType(FlatmatesAvatar), findsNWidgets(2));
    });

    testWidgets('keep swiping button is present', (tester) async {
      await tester.pumpWidget(
        wrap(
          MatchCelebrationScreen(
            userName: 'Alice',
            userImageUrl: null,
            peerName: 'Bob',
            peerImageUrl: null,
            onOpenChat: () {},
            onKeepSwiping: () {},
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const Key('match_keep_swiping')), findsOneWidget);
    });

    testWidgets('send message button is present', (tester) async {
      await tester.pumpWidget(
        wrap(
          MatchCelebrationScreen(
            userName: 'Alice',
            userImageUrl: null,
            peerName: 'Bob',
            peerImageUrl: null,
            onOpenChat: () {},
            onKeepSwiping: () {},
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const Key('match_open_chat')), findsOneWidget);
    });
  });
}
