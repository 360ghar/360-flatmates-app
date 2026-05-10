import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/discover/presentation/widgets/discover_header.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('discover header renders real city counter text when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      testableWidget(
        child: const Scaffold(
          body: DiscoverHeader(
            greeting: 'Hi, Test',
            location: 'Koramangala, Bangalore',
            avatarUrl: null,
            userName: 'Test User',
            cityCounterLabel: '12 people looking in Bangalore right now',
          ),
        ),
      ),
    );

    expect(
      find.text('12 people looking in Bangalore right now'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.people_outline_rounded), findsOneWidget);
  });
}
