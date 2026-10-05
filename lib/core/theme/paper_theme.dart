import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

/// Scene and paper-detail tokens. See DESIGN.md §1 (scene layers) and §5.
///
/// Read with `PaperTheme.of(context)` or `Theme.of(context).extension`.
@immutable
class PaperTheme extends ThemeExtension<PaperTheme> {
  const PaperTheme({
    required this.hillFar,
    required this.hillNear,
    required this.townFar,
    required this.town,
    required this.window,
    required this.tree,
    required this.sun,
    required this.cloud,
    required this.layerShadow,
    required this.grainOpacity,
  });

  static const light = PaperTheme(
    hillFar: Color(0xFFC3D5C8),
    hillNear: Color(0xFF93B39F),
    townFar: Color(0xFFDDB3A0),
    town: AppSemanticColors.clay,
    window: Color(0xFFF6EBD9),
    tree: AppSemanticColors.pine,
    sun: AppSemanticColors.marigold,
    cloud: AppSemanticColors.paper3,
    layerShadow: Color(0x3823201C), // ink @ 22 %
    grainOpacity: 0.04,
  );

  static const dark = PaperTheme(
    hillFar: Color(0xFF1D2A22),
    hillNear: Color(0xFF26392E),
    townFar: Color(0xFF3A2A23),
    town: Color(0xFF8A4128),
    window: AppSemanticColors.darkMarigold, // lit at night
    tree: Color(0xFF3F6F58),
    sun: AppSemanticColors.darkMarigold,
    cloud: AppSemanticColors.darkPaper3,
    layerShadow: Color(0x80000000), // black @ 50 %
    grainOpacity: 0.04,
  );

  static PaperTheme of(Object brightnessOrContext) {
    if (brightnessOrContext is Brightness) {
      return brightnessOrContext == Brightness.dark ? dark : light;
    }
    final theme = Theme.of(brightnessOrContext as BuildContext);
    return theme.extension<PaperTheme>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  final Color hillFar;
  final Color hillNear;
  final Color townFar;
  final Color town;
  final Color window;
  final Color tree;
  final Color sun;
  final Color cloud;

  /// Colour of the tight down-right shadow each scene layer casts.
  final Color layerShadow;

  /// Opacity of the paper grain painted behind content.
  final double grainOpacity;

  @override
  PaperTheme copyWith({
    Color? hillFar,
    Color? hillNear,
    Color? townFar,
    Color? town,
    Color? window,
    Color? tree,
    Color? sun,
    Color? cloud,
    Color? layerShadow,
    double? grainOpacity,
  }) => PaperTheme(
    hillFar: hillFar ?? this.hillFar,
    hillNear: hillNear ?? this.hillNear,
    townFar: townFar ?? this.townFar,
    town: town ?? this.town,
    window: window ?? this.window,
    tree: tree ?? this.tree,
    sun: sun ?? this.sun,
    cloud: cloud ?? this.cloud,
    layerShadow: layerShadow ?? this.layerShadow,
    grainOpacity: grainOpacity ?? this.grainOpacity,
  );

  @override
  PaperTheme lerp(PaperTheme? other, double t) {
    if (other == null) return this;
    return PaperTheme(
      hillFar: Color.lerp(hillFar, other.hillFar, t)!,
      hillNear: Color.lerp(hillNear, other.hillNear, t)!,
      townFar: Color.lerp(townFar, other.townFar, t)!,
      town: Color.lerp(town, other.town, t)!,
      window: Color.lerp(window, other.window, t)!,
      tree: Color.lerp(tree, other.tree, t)!,
      sun: Color.lerp(sun, other.sun, t)!,
      cloud: Color.lerp(cloud, other.cloud, t)!,
      layerShadow: Color.lerp(layerShadow, other.layerShadow, t)!,
      grainOpacity: grainOpacity + (other.grainOpacity - grainOpacity) * t,
    );
  }
}
