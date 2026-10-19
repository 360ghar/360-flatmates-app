import 'package:flatmates_app/core/domain/wire_enums.dart';
import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/chats/presentation/chat_peer_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_helpers.dart';

const _peer = ChatPeer(id: 201, fullName: 'Ananya Krishnamurthy');

Future<void> _pump(
  WidgetTester tester, {
  ConversationSummaryModel? conversation,
}) async {
  final widget = await testableWidgetAsync(
    overrides: [
      peerProfileProvider.overrideWith((ref, id) async => null),
      peerCompatibilityProvider.overrideWith((ref, id) async => null),
    ],
    child: ChatPeerProfilePage(userId: 201, conversation: conversation),
  );
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Finder _action(String key) => find.byKey(ValueKey(key), skipOffstage: false);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetTestAppPreferences();
  });

  group('ChatPeerProfilePage actions', () {
    testWidgets('an open profile match has a Call action', (tester) async {
      await _pump(
        tester,
        conversation: const ConversationSummaryModel(
          id: 1,
          source: ConversationSource.profileMatch,
          peer: _peer,
        ),
      );

      expect(_action('peer_action_message'), findsOneWidget);
      expect(_action('peer_action_call'), findsOneWidget);
      expect(_action('peer_action_report'), findsOneWidget);
    });

    testWidgets('a listing conversation has no Call action', (tester) async {
      await _pump(
        tester,
        conversation: const ConversationSummaryModel(
          id: 2,
          source: ConversationSource.listingInterest,
          peer: _peer,
        ),
      );

      expect(_action('peer_action_message'), findsOneWidget);
      expect(_action('peer_action_call'), findsNothing);
      expect(_action('peer_action_report'), findsOneWidget);
    });

    testWidgets('an unmatched profile match has no Call action', (
      tester,
    ) async {
      await _pump(
        tester,
        conversation: const ConversationSummaryModel(
          id: 3,
          source: ConversationSource.profileMatch,
          status: ConversationStatus.archived,
          peer: _peer,
        ),
      );

      expect(_action('peer_action_call'), findsNothing);
    });

    testWidgets('no conversation means no Call action', (tester) async {
      await _pump(tester);

      expect(_action('peer_action_call'), findsNothing);
      expect(_action('peer_action_message'), findsOneWidget);
    });
  });
}
