import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/discover/presentation/widgets/discover_header.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('discover header renders greeting and avatar', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: const Scaffold(
          body: DiscoverHeader(
            greeting: 'Hi, Test',
            location: 'Koramangala, Bangalore',
            avatarUrl: null,
            userName: 'Test User',
          ),
        ),
      ),
    );

    expect(find.text('Hi, Test'), findsOneWidget);
    expect(find.text('TU'), findsOneWidget);
  });
}
