import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flatmates_app/features/shared/presentation/flatmates_price_text.dart';

void main() {
  group('FlatmatesPriceText.formatRupee', () {
    test('formats three-digit amount', () {
      expect(FlatmatesPriceText.formatRupee(500), '₹500');
    });

    test('formats four-digit amount with Indian grouping', () {
      expect(FlatmatesPriceText.formatRupee(24000), '₹24,000');
    });

    test('formats five-digit amount', () {
      expect(FlatmatesPriceText.formatRupee(100000), '₹1,00,000');
    });

    test('formats six-digit amount', () {
      expect(FlatmatesPriceText.formatRupee(500000), '₹5,00,000');
    });

    test('formats seven-digit amount', () {
      expect(FlatmatesPriceText.formatRupee(5000000), '₹50,00,000');
    });

    test('formats zero', () {
      expect(FlatmatesPriceText.formatRupee(0), '₹0');
    });

    test('formats one-digit amount', () {
      expect(FlatmatesPriceText.formatRupee(5), '₹5');
    });

    test('formats two-digit amount', () {
      expect(FlatmatesPriceText.formatRupee(50), '₹50');
    });

    test('formats negative amount as absolute value', () {
      expect(FlatmatesPriceText.formatRupee(-24000), '₹24,000');
    });
  });

  group('FlatmatesPriceText widget', () {
    testWidgets('hero variant renders formatted amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FlatmatesPriceText.hero(amount: 24000)),
        ),
      );

      expect(find.text('₹24,000'), findsOneWidget);
    });

    testWidgets('hero variant renders amount with period', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesPriceText.hero(amount: 24000, period: 'mo'),
          ),
        ),
      );

      expect(find.text('₹24,000 / mo'), findsOneWidget);
    });

    testWidgets('card variant renders formatted amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FlatmatesPriceText.card(amount: 15000)),
        ),
      );

      expect(find.text('₹15,000'), findsOneWidget);
    });

    testWidgets('inline variant renders formatted amount', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FlatmatesPriceText.inline(amount: 8000)),
        ),
      );

      expect(find.text('₹8,000'), findsOneWidget);
    });

    testWidgets('inline variant renders amount with period', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlatmatesPriceText.inline(amount: 8000, period: 'night'),
          ),
        ),
      );

      expect(find.text('₹8,000 / night'), findsOneWidget);
    });

    testWidgets('uses correct font sizes per variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FlatmatesPriceText.hero(amount: 100),
                FlatmatesPriceText.card(amount: 100),
                FlatmatesPriceText.inline(amount: 100),
              ],
            ),
          ),
        ),
      );

      final texts = find.byType(Text);
      expect(
        tester.widgetList<Text>(texts).map((t) => t.style?.fontSize),
        containsAll([26.0, 18.0, 14.0]),
      );
    });
  });
}
