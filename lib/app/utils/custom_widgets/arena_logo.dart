import 'package:flutter/material.dart';

import '../../config/app_assets.dart';
import '../../config/arena_theme.dart';
import '../utils.dart';

/// The ArenaBook stadium mark. Always use this widget instead of loading the image directly.
///
/// The asset is white line art on transparency, so it is tinted at draw time ([BlendMode.srcIn]):
/// drawn raw, it would vanish on light backgrounds. Default colour is the theme's emerald text
/// shade (readable in dark and light mode); pass [color] for coloured tiles, e.g. `onAccent`
/// on the emerald→lime gradient.
class ArenaLogo extends StatelessWidget {
  const ArenaLogo({super.key, this.size = 24, this.color, this.semanticLabel = 'ArenaBook logo'});

  final double size;
  final Color? color;

  /// null = decorative (when a visible "ArenaBook" wordmark sits right next to it).
  final String? semanticLabel;

  static String get assetPath => Utils.getImagePath(AppAssets.images.logo);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.extension<ArenaColors>()?.cricketText ?? theme.colorScheme.primary;
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: tint,
      colorBlendMode: BlendMode.srcIn,
      filterQuality: FilterQuality.medium, // smooth edges when the 512px mark is drawn small
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
