import 'package:flatmates_app/features/chats/chats_repository.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/flatmate_profile_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('a failed peer profile offers Retry, and Retry refetches (M2)', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      testableWidget(
        overrides: [
          // fetchPeerProfile returns null on any failure.
          peerProfileProvider.overrideWith((ref, userId) async {
            calls++;
            return null;
          }),
        ],
        child: const Scaffold(
          body: FlatmateProfileSheet(userId: 7, nameFallback: 'Asha'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('a failed peer profile keeps the caller-known identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      testableWidget(
        overrides: [
          peerProfileProvider.overrideWith((ref, userId) async => null),
        ],
        child: const Scaffold(
          body: FlatmateProfileSheet(userId: 7, nameFallback: 'Asha'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The sheet still says who failed to load, not just a generic error.
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
