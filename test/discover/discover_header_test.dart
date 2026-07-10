import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/discover_header.dart';

import '../helpers/test_helpers.dart';

void main() {
  testWidgets('discover header renders greeting and avatar', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: const Scaffold(
          body: DiscoverHeader(
            greetingLabel: 'Hi',
            name: 'Test',
            location: 'Koramangala, Bangalore',
            avatarUrl: null,
            userName: 'Test User',
          ),
        ),
      ),
    );

    expect(find.text('Hi, Test', findRichText: true), findsOneWidget);
    expect(find.text('TU'), findsOneWidget);
  });

  test('locationPreview caps at 15 characters with ellipsis', () {
    expect(DiscoverHeader.locationPreview('Short'), 'Short');
    expect(
      DiscoverHeader.locationPreview('Koramangala, Bangalore'),
      'Koramangala, Ba…',
    );
    expect(
      DiscoverHeader.locationPreview('  ExactlyFifteenX  '),
      'ExactlyFifteenX',
    );
  });

  testWidgets('discover header shows truncated location preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      testableWidget(
        child: const Scaffold(
          body: DiscoverHeader(
            greetingLabel: 'Afternoon',
            name: 'Saksham',
            location: 'Koramangala, Bangalore',
            avatarUrl: null,
            userName: 'Saksham Mittal',
          ),
        ),
      ),
    );

    expect(find.text('Koramangala, Ba…'), findsOneWidget);
    expect(find.text('Koramangala, Bangalore'), findsNothing);
  });

  testWidgets('discover header paints name in brand pink', (tester) async {
    await tester.pumpWidget(
      testableWidget(
        child: const Scaffold(
          body: DiscoverHeader(
            greetingLabel: 'Afternoon',
            name: 'Saksham',
            location: 'Delhi',
            avatarUrl: null,
            userName: 'Saksham Mittal',
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('Saksham'),
      ),
    );

    TextSpan? nameSpan;
    richText.text.visitChildren((span) {
      if (span is TextSpan && span.text == 'Saksham') {
        nameSpan = span;
        return false;
      }
      return true;
    });

    expect(nameSpan, isNotNull);
    expect(nameSpan!.style?.color, AppSemanticColors.primary);
  });
}
