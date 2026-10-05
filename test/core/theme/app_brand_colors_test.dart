import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/core/theme/app_brand_colors.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_button.dart';

void main() {
  group('AppBrandColors.google', () {
    test('light matches the Google identity guidelines', () {
      final brand = AppBrandColors.google(Brightness.light);

      expect(brand.fill, const Color(0xFFFFFFFF));
      expect(brand.label, const Color(0xFF1F1F1F));
      expect(brand.stroke, const Color(0xFF747775));
      expect(brand.pressed, const Color(0xFFF8F9FA));
    });

    test('dark is unchanged', () {
      final brand = AppBrandColors.google(Brightness.dark);

      expect(brand.fill, const Color(0xFF131314));
      expect(brand.label, const Color(0xFFE3E3E3));
      expect(brand.stroke, const Color(0xFF8E918F));
      expect(brand.pressed, const Color(0xFF1E1F20));
    });
  });

  group('FlatmatesButton.google', () {
    Future<void> pumpGoogleButton(WidgetTester tester, Brightness brightness) {
      return tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: Center(
              child: FlatmatesButton.google(
                label: 'Continue with Google',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
    }

    ButtonStyle buttonStyle(WidgetTester tester) =>
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style!;

    for (final brightness in Brightness.values) {
      testWidgets('paints the $brightness brand palette', (tester) async {
        await pumpGoogleButton(tester, brightness);
        await tester.pump();

        final brand = AppBrandColors.google(brightness);
        final style = buttonStyle(tester);

        expect(
          style.backgroundColor?.resolve(const <WidgetState>{}),
          brand.fill,
        );
        expect(
          style.foregroundColor?.resolve(const <WidgetState>{}),
          brand.label,
        );
        expect(style.side?.resolve(const <WidgetState>{})?.color, brand.stroke);
        expect(
          style.overlayColor?.resolve(const <WidgetState>{WidgetState.pressed}),
          brand.pressed,
        );

        // The label itself is brand-coloured, not theme-coloured.
        final label = tester.widget<Text>(
          find.descendant(
            of: find.byType(OutlinedButton),
            matching: find.byType(Text),
          ),
        );
        expect(label.style?.color, brand.label);
      });
    }

    testWidgets('a disabled button uses the theme disabled stroke, not brand', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: const Scaffold(
            body: Center(
              child: FlatmatesButton.google(
                label: 'Continue with Google',
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      final brand = AppBrandColors.google(Brightness.light);
      final style = buttonStyle(tester);
      final stroke = style.side?.resolve(const <WidgetState>{})?.color;

      expect(stroke, isNot(brand.stroke));
    });
  });
}
