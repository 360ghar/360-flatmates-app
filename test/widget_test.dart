import 'package:flutter_test/flutter_test.dart';
import 'package:flatmates_app/core/theme/app_palette.dart';
import 'package:flatmates_app/features/shared/presentation/flatmates_price_text.dart';

void main() {
  test('AppPalette falls back to ink on paper for unknown storage values', () {
    expect(AppPaletteX.fromStorage('unknown-value'), AppPalette.inkOnPaper);
  });

  test('FlatmatesPriceText formats Indian currency groups', () {
    expect(FlatmatesPriceText.formatRupee(999), '₹999');
    expect(FlatmatesPriceText.formatRupee(16500), '₹16,500');
    expect(FlatmatesPriceText.formatRupee(165000), '₹1,65,000');
    expect(FlatmatesPriceText.formatRupee(1000000), '₹10,00,000');
  });
}
