import 'package:flutter/material.dart';

/// Petit badge "Bientot" signalant une fonctionnalite a venir (pas encore
/// disponible). Couleur ambre, lisible sur fond clair comme sur degrade.
/// [dense] : version compacte pour les espaces serres (ex. icone de barre).
class SoonBadge extends StatelessWidget {
  const SoonBadge({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 4 : 8,
        vertical: dense ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B), // ambre "a venir"
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Bientot',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: dense ? 8 : 10,
          height: 1,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
