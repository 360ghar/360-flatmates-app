import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:flatmates_app/features/profile/help_safety_page.dart';
import 'package:flatmates_app/l10n/gen/app_localizations.dart';

Widget _helpSafetyRouter({String initialLocation = '/help-safety'}) {
  return MaterialApp.router(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    routerConfig: GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/help-safety',
          builder: (context, state) => const HelpSafetyPage(),
          routes: [
            GoRoute(
              path: 'faq',
              builder: (context, state) =>
                  const HelpSafetyTopicPage(topic: HelpSafetyTopic.faq),
            ),
            GoRoute(
              path: 'popular-topics',
              builder: (context, state) => const HelpSafetyTopicPage(
                topic: HelpSafetyTopic.popularTopics,
              ),
            ),
            GoRoute(
              path: 'bookings',
              builder: (context, state) => const HelpSafetyTopicPage(
                topic: HelpSafetyTopic.bookingAgreements,
              ),
            ),
            GoRoute(
              path: 'account',
              builder: (context, state) => const HelpSafetyTopicPage(
                topic: HelpSafetyTopic.accountProfile,
              ),
            ),
            GoRoute(
              path: 'contact',
              builder: (context, state) =>
                  const HelpSafetyTopicPage(topic: HelpSafetyTopic.contact),
            ),
          ],
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/blocked-users',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

void main() {
  group('HelpSafetyPage', () {
    testWidgets('renders localized help and safety options', (tester) async {
      await tester.pumpWidget(_helpSafetyRouter());
      await tester.pumpAndSettle();

      expect(find.text('Help & Safety'), findsOneWidget);
      expect(find.text('Your safety is our priority'), findsOneWidget);
      expect(find.text('FAQ'), findsOneWidget);
      expect(find.text('Find answers to common questions'), findsOneWidget);
      expect(find.text('Popular Topics'), findsOneWidget);
      expect(find.text('Payments & Refunds'), findsNothing);
      expect(find.text('Booking & Agreements'), findsOneWidget);
      expect(find.text('Account & Profile'), findsOneWidget);
      expect(find.text('Contact support'), findsWidgets);
      await tester.ensureVisible(find.text('Report a Bug'));
      await tester.pumpAndSettle();
      expect(find.text('Report a Bug'), findsOneWidget);
      await tester.ensureVisible(find.text('Request a Feature'));
      await tester.pumpAndSettle();
      expect(find.text('Request a Feature'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('help_chat_with_us_button')), findsOneWidget);

      expect(find.text('Support available 24/7'), findsOneWidget);
    });

    testWidgets('all help topics open valid pages', (tester) async {
      await tester.pumpWidget(_helpSafetyRouter());
      await tester.pumpAndSettle();

      final topics = <String, String>{
        'FAQ': 'How do I start finding a flatmate?',
        'Popular Topics': 'Safer first meetings',
        'Booking & Agreements': 'Before confirming a move',
        'Account & Profile': 'Edit profile details',
      };

      for (final entry in topics.entries) {
        await tester.ensureVisible(find.text(entry.key));
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(entry.value), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      await tester.ensureVisible(
        find.byKey(const Key('help_chat_with_us_button')),
      );
      await tester.tap(find.byKey(const Key('help_chat_with_us_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('What to include'), findsOneWidget);
      expect(find.text('Email support'), findsOneWidget);
    });
  });
}
