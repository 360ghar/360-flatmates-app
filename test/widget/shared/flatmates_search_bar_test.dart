import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/shared/presentation/app_icons.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_search_bar.dart';

void main() {
  group('FlatmatesSearchBar', () {
    testWidgets('renders hint text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FlatmatesSearchBar(hint: 'Search flatmates')),
        ),
      );

      expect(find.text('Search flatmates'), findsOneWidget);
    });

    testWidgets('renders default search leading icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FlatmatesSearchBar())),
      );

      expect(find.byIcon(AppIcons.search), findsOneWidget);
    });

    testWidgets('renders custom leading icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesSearchBar(leadingIcon: Icons.location_on),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(AppIcons.search), findsNothing);
    });

    testWidgets('renders trailing icon button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesSearchBar(
              trailingIcon: Icons.tune,
              trailingTooltip: 'Filters',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byTooltip('Filters'), findsOneWidget);
    });

    testWidgets('trailing icon tap calls onTrailingTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesSearchBar(
              trailingIcon: Icons.tune,
              onTrailingTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('onChanged fires when text is entered', (tester) async {
      String? changedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesSearchBar(
              onChanged: (value) => changedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hello');
      await tester.pumpAndSettle();

      expect(changedValue, 'hello');
    });

    testWidgets('onSubmitted fires on submit', (tester) async {
      String? submittedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesSearchBar(
              onSubmitted: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'query');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submittedValue, 'query');
    });

    testWidgets('readOnly prevents text entry but calls onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlatmatesSearchBar(
              readOnly: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('has a fixed height of 48', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FlatmatesSearchBar())),
      );

      final size = tester.getSize(find.byType(FlatmatesSearchBar));
      expect(size.height, 48);
    });
  });
}
