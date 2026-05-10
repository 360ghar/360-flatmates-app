import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

// Legacy aliases — kept for backward compatibility.
// New code should import app_semantic_colors.dart directly.
const kDarkHeading = AppSemanticColors.ink;
const kMutedText = AppSemanticColors.ink2;
const kLavenderBg = AppSemanticColors.paper;
const kPeerBubbleBg = AppSemanticColors.paper3;
const kSuccessBg = AppSemanticColors.greenSoft;
const kSuccessText = AppSemanticColors.greenInk;

enum AppPalette { inkOnPaper, electricIndigo, emberCoral, monsoonTeal }

extension AppPaletteX on AppPalette {
  Color get seedColor {
    switch (this) {
      case AppPalette.inkOnPaper:
        return AppSemanticColors.accent;
      case AppPalette.electricIndigo:
        return AppSemanticColors.blueMid;
      case AppPalette.emberCoral:
        return AppSemanticColors.orangeMid;
      case AppPalette.monsoonTeal:
        return AppSemanticColors.tealMid;
    }
  }

  String get storageValue {
    switch (this) {
      case AppPalette.inkOnPaper:
        return 'ink_on_paper';
      case AppPalette.electricIndigo:
        return 'electric_indigo';
      case AppPalette.emberCoral:
        return 'ember_coral';
      case AppPalette.monsoonTeal:
        return 'monsoon_teal';
    }
  }

  String get label {
    switch (this) {
      case AppPalette.inkOnPaper:
        return 'Ink on Paper';
      case AppPalette.electricIndigo:
        return 'Paper Blue';
      case AppPalette.emberCoral:
        return 'Warm Clay';
      case AppPalette.monsoonTeal:
        return 'Monsoon Teal';
    }
  }

  static AppPalette fromStorage(String? value) {
    return AppPalette.values.firstWhere(
      (palette) => palette.storageValue == value,
      orElse: () => AppPalette.inkOnPaper,
    );
  }
}
