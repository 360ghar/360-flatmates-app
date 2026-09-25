import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';

/// Emoji picker colours from the paper palette (the package defaults are a
/// light grey sheet with blue accents in both themes).
Config chatEmojiPickerConfig(BuildContext context) {
  final b = Theme.of(context).brightness;
  final paper = AppSemanticColors.paper1For(b);
  final clay = AppSemanticColors.clayFor(b);
  final muted = AppSemanticColors.textTertiaryFor(b);
  return Config(
    locale: Localizations.localeOf(context),
    emojiViewConfig: EmojiViewConfig(backgroundColor: paper),
    categoryViewConfig: CategoryViewConfig(
      backgroundColor: paper,
      indicatorColor: clay,
      iconColor: muted,
      iconColorSelected: clay,
      backspaceColor: clay,
      dividerColor: AppSemanticColors.hairlineFor(b),
    ),
    bottomActionBarConfig: BottomActionBarConfig(
      backgroundColor: paper,
      buttonColor: paper,
      buttonIconColor: clay,
    ),
    searchViewConfig: SearchViewConfig(
      backgroundColor: paper,
      buttonIconColor: muted,
    ),
  );
}
