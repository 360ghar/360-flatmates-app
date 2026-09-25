import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Consistent rupee formatting. Never purple per DESIGN.md.
///
/// Use the named constructors for size variants: [FlatmatesPriceText.hero],
/// [FlatmatesPriceText.card], [FlatmatesPriceText.inline].
class FlatmatesPriceText extends StatelessWidget {
  // ignore: unused_element
  const FlatmatesPriceText._({
    required this.amount,
    required this.fontSize,
    required this.fontWeight,
    // ignore: unused_element_parameter
    this.period,
    // ignore: unused_element_parameter
    this.color,
  });

  /// h2 size (26), semibold — listing hero price.
  const FlatmatesPriceText.hero({
    required this.amount,
    super.key,
    this.period,
    this.color,
  }) : fontSize = AppTypography.h2Size,
       fontWeight = FontWeight.w600;

  /// Title size (17), semibold — compact card price.
  const FlatmatesPriceText.card({
    required this.amount,
    super.key,
    this.period,
    this.color,
  }) : fontSize = AppTypography.titleSize,
       fontWeight = FontWeight.w600;

  /// Body-sm size (14), medium — inline price.
  const FlatmatesPriceText.inline({
    required this.amount,
    super.key,
    this.period,
    this.color,
  }) : fontSize = AppTypography.bodySmallSize,
       fontWeight = FontWeight.w500;

  final int amount;
  final String? period;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor =
        color ?? AppSemanticColors.textPrimaryFor(theme.brightness);

    final formatted = formatRupee(amount);
    final text = period != null ? '$formatted / $period' : formatted;

    // Body font with tabular figures (DESIGN.md §2: numbers in data).
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: resolvedColor,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  static final _rupee = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  /// Indian grouping without decimals: ₹24,000, ₹1,00,000. Always shows the
  /// magnitude (a negative amount renders like its positive value).
  static String formatRupee(int amount) => _rupee.format(amount.abs());

  /// Compact rupee for tight surfaces: ₹1.5L, ₹10L.
  ///
  /// At or above a lakh the amount always compacts to `L`. Below a lakh the
  /// default is the full grouped form from [formatRupee] (₹24,000); pass
  /// [thousands] to compact those to `K` instead (₹24K) — map markers need
  /// that, listing cards do not.
  static String formatCompact(int amount, {bool thousands = false}) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      final value = lakhs.toStringAsFixed(lakhs >= 10 ? 1 : 2);
      final compact = value.replaceAll(RegExp(r'\.?0+$'), '');
      return '₹${compact}L';
    }
    if (!thousands) return formatRupee(amount);
    final k = amount / 1000;
    return '₹${k.toStringAsFixed(k == k.roundToDouble() ? 0 : 1)}K';
  }
}
