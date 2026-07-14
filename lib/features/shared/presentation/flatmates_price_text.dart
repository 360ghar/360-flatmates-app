import 'package:flutter/material.dart';

import '../../../core/theme/app_semantic_colors.dart';

/// Consistent rupee formatting. Never purple per DESIGN.md.
///
/// Use the named constructors for size variants:
/// - [FlatmatesPriceText.hero] — 26sp bold, listing card hero
/// - [FlatmatesPriceText.card] — 18sp semiBold, compact card
/// - [FlatmatesPriceText.inline] — 14sp medium, inline/context
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

  /// 26sp bold — listing card hero price.
  const FlatmatesPriceText.hero({
    required this.amount,
    super.key,
    this.period,
    this.color,
  }) : fontSize = 26,
       fontWeight = FontWeight.w700;

  /// 18sp semiBold — compact card price.
  const FlatmatesPriceText.card({
    required this.amount,
    super.key,
    this.period,
    this.color,
  }) : fontSize = 18,
       fontWeight = FontWeight.w600;

  /// 14sp medium — inline/context price.
  const FlatmatesPriceText.inline({
    required this.amount,
    super.key,
    this.period,
    this.color,
  }) : fontSize = 14,
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

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: resolvedColor,
        height: 1.2,
      ),
    );
  }

  /// Formats an integer as Indian currency: ₹24,000
  static String formatRupee(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer('₹');

    if (str.length <= 3) {
      buffer.write(str);
    } else {
      final lastThree = str.substring(str.length - 3);
      final leading = str.substring(0, str.length - 3);
      final firstGroupLength = leading.length % 2 == 0 ? 2 : 1;
      final firstPart = leading.substring(0, firstGroupLength);
      buffer.write(firstPart);
      var remaining = leading.substring(firstPart.length);
      while (remaining.isNotEmpty) {
        buffer.write(',');
        buffer.write(remaining.substring(0, 2));
        remaining = remaining.substring(2);
      }
      buffer.write(',');
      buffer.write(lastThree);
    }

    return buffer.toString();
  }
}
