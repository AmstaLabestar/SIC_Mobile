import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Gradients du design system.
///
/// Le gradient principal (bleu -> emeraude) est reserve a la piece maitresse :
/// la carte solde. Les autres sont des teintes douces pour les fonds d'icones.
class AppGradients {
  const AppGradients._();

  /// Gradient principal de la carte solde (bleu -> bleu -> emeraude, 145deg).
  static const LinearGradient hero = LinearGradient(
    begin: Alignment(-0.8, -0.8),
    end: Alignment(0.8, 0.8),
    colors: AppColors.heroGradient,
  );

  /// Teinte douce d'une couleur (fond d'icone d'action rapide).
  static LinearGradient soft(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.16),
        color.withOpacity(0.04),
      ],
    );
  }
}
