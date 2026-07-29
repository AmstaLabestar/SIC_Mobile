import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_radii.dart';
import '../constants/app_shadows.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../widgets/pressable.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _items = <_NavItemData>[
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
      location: '/dashboard',
    ),
    _NavItemData(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Transactions',
      location: '/transactions',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Mon compte',
      location: '/compte',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(location);

    return Scaffold(
      // Rendu direct de la page : PAS d'AnimatedSwitcher ici. Un AnimatedSwitcher
      // garde les deux pages vivantes pendant la transition, ce qui duplique
      // toute GlobalKey interne d'une page (crash "Duplicate GlobalKey" observe
      // sur /dashboard). Les transitions inter-onglets sont a gerer via GoRouter
      // (pageBuilder) si besoin, pas par un switch de widget sur l'enfant du shell.
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.xxl),
              boxShadow: AppShadows.nav,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _items.length; i++)
                  _NavItem(
                    data: _items[i],
                    selected: i == selectedIndex,
                    onTap: () => context.go(_items[i].location),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/compte')) return 2;
    return 0;
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.location,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String location;
}

/// Onglet style "pilule" : actif = pilule bleu clair avec icone + label,
/// inactif = icone seule grise. Transition de largeur animee (Revolut-like).
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textTertiary;

    return Expanded(
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.95,
        semanticLabel: data.label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                selected ? data.activeIcon : data.icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
