import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Badge du type de compte : **« Compte Agent »** (PDV, orange/boutique) ou
/// **« Compte Client »** (grand public, bleu/personne).
///
/// Widget partagé pour afficher le rôle de façon **cohérente** partout (accueil
/// agent, accueil client, écran compte).
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.isAgent, this.compact = false});

  final bool isAgent;

  /// Version compacte (icône + libellé plus petits) pour les en-têtes denses.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = isAgent ? const Color(0xFF1E3A8A) : AppColors.primary;
    final icon = isAgent ? Icons.storefront_rounded : Icons.person_rounded;
    final label = isAgent ? 'Compte Agent' : 'Compte Client';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 9.5 : 10,
            ),
          ),
        ],
      ),
    );
  }
}
