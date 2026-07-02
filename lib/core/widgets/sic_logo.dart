import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Logo de marque SIC presente dans une tuile blanche arrondie avec une ombre
/// douce. Le visuel source etant un JPEG a fond blanc (sans transparence), la
/// tuile blanche permet un fondu propre sur n'importe quel fond de l'app.
class SicLogo extends StatelessWidget {
  const SicLogo({super.key, this.size = 88, this.radius, this.elevated = true});

  final double size;
  final double? radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        AppAssets.logoLight,
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => const SizedBox.shrink(),
      ),
    );
  }
}
