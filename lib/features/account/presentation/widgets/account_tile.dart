import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/pressable.dart';

/// Tuile d'action des ecrans Compte / Securite : icone, titre, sous-titre,
/// chevron. `danger` pour les actions destructrices (deconnexion).
class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primary;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: title,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: danger
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: danger
                  ? const Color(0xFFEF4444).withOpacity(0.04)
                  : const Color(0xFF1E3A8A).withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: danger
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: danger
                  ? const Color(0xFFF87171)
                  : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}
