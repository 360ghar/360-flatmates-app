import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flatmates_app/features/discover/presentation/widgets/discover_header.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  group('DiscoverHeader', () {
    testWidgets('renders greeting and avatar', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DiscoverHeader(
            greetingLabel: 'Afternoon',
            name: 'Saksham',
            location: 'Koramangala',
            avatarUrl: null,
            userName: 'Saksham Mittal',
          ),
        ),
      );

      expect(find.textContaining('Afternoon'), findsOneWidget);
      expect(find.textContaining('Saksham'), findsWidgets);
    });

    testWidgets('locationPreview caps at 15 characters with ellipsis', (
      tester,
    ) async {
      const longLocation = 'Indiranagar 100 Feet Road';
      final preview = DiscoverHeader.locationPreview(longLocation);
      expect(preview.length, 16); // 15 chars + ellipsis
      expect(preview.endsWith('…'), isTrue);

      const shortLocation = 'Koramangala';
      expect(DiscoverHeader.locationPreview(shortLocation), 'Koramangala');
    });

    testWidgets('discover header shows truncated location preview', (
      tester,
    ) async {
      const longLocation = 'Indiranagar 100 Feet Road';
      await tester.pumpWidget(
        wrap(
          const DiscoverHeader(
            greetingLabel: 'Morning',
            name: 'Test',
            location: longLocation,
            avatarUrl: null,
            userName: 'Test User',
          ),
        ),
      );

      // The location chip should show the truncated preview, not the full
      // location string.
      final expectedPreview = DiscoverHeader.locationPreview(longLocation);
      expect(find.text(expectedPreview), findsOneWidget);
      expect(find.text(longLocation), findsNothing);
    });

    testWidgets('discover header paints name in brand pink', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DiscoverHeader(
            greetingLabel: 'Evening',
            name: 'PinkName',
            location: 'Bangalore',
            avatarUrl: null,
            userName: 'Pink Name',
          ),
        ),
      );

      // Find the Text.rich widget containing the greeting.
      final richText = tester.widget<Text>(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.textSpan != null,
        ),
      );

      // The second TextSpan (the name) should use the brand primary color.
      final span = richText.textSpan as TextSpan?;
      expect(span, isNotNull);
      final children = span!.children;
      expect(children, isNotNull);
      expect(children!.length, greaterThanOrEqualTo(2));

      final nameSpan = children[1] as TextSpan;
      expect(nameSpan.text, 'PinkName');
      expect(nameSpan.style?.color, AppSemanticColors.primary);
    });
  });
}
