import 'package:flutter/material.dart';

import '../../../app/config/app_assets.dart';
import '../../../app/utils/custom_widgets/svg_widget.dart';

/// The WhatsApp glyph, used like an [Icon]: colour and size come from the surrounding IconTheme unless given.
class WhatsAppLogo extends StatelessWidget {
  const WhatsAppLogo({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = (size ?? theme.size ?? 24) * 0.95; // the glyph fills its box; trimmed to match Material icon weight
    return SizedBox.square(
      dimension: size ?? theme.size ?? 24,
      child: Center(
        child: SvgWidget(name: AppAssets.svg.whatsApp, color: color ?? theme.color ?? Colors.black, width: s, height: s),
      ),
    );
  }
}
