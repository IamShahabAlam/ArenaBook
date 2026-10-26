import 'package:flutter/material.dart';

import '../../../app/config/app_client_config.dart';
import '../../../app/config/arena_theme.dart';

/// The client's logo from `assets/clients/<id>/`, else (or if it fails to load) a monogram of the business name.
class ClientLogo extends StatelessWidget {
  const ClientLogo({super.key, this.size = 44, this.name, this.logoAsset, this.radius, this.elevation = false});

  final double size;

  /// Overrides the client's name / logo file (null = the client's).
  final String? name;
  final String? logoAsset;

  /// Corner radius; null = scales with [size].
  final double? radius;

  /// Adds a soft accent glow under the monogram.
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    final c = context.arena;
    final client = AppClientConfig.client;
    final businessName = (name ?? client.name).trim();
    final assetName = logoAsset ?? client.logoAsset;
    final r = BorderRadius.circular(radius ?? (size * 0.32).clamp(10, 22));

    Widget buildMonogram() {
      final initial = businessName.isNotEmpty ? businessName[0].toUpperCase() : 'A';
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: ArenaColors.ctaGradient,
          borderRadius: r,
          boxShadow: elevation ? [BoxShadow(color: ArenaColors.emerald.withValues(alpha: 0.28), blurRadius: size * 0.28, offset: const Offset(0, 2))] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(fontFamily: 'Outfit', fontSize: size * 0.48, fontWeight: FontWeight.w800, color: c.onAccent, height: 1),
        ),
      );
    }

    if (assetName != null && assetName.isNotEmpty) {
      final decodeSize = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
      return ClipRRect(
        borderRadius: r,
        child: Image(
          // Decode at display size but keep the aspect ratio (cacheWidth + cacheHeight would stretch a wide logo).
          image: ResizeImage(AssetImage(client.asset(assetName)), width: decodeSize, height: decodeSize, policy: ResizeImagePolicy.fit),
          width: size,
          height: size,
          fit: BoxFit.contain, // a logo is never cropped
          errorBuilder: (context, error, stackTrace) => buildMonogram(),
        ),
      );
    }

    return buildMonogram();
  }
}
