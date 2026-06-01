import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.10),
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => _goToTab(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.sim_card_outlined),
            selectedIcon: Icon(Icons.sim_card_rounded),
            label: 'Puces',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Alertes',
          ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/dashboard/sims')) {
      return 1;
    }

    if (location.startsWith('/dashboard/alerts')) {
      return 2;
    }

    return 0;
  }

  void _goToTab(BuildContext context, int index) {
    final location = switch (index) {
      0 => '/dashboard',
      1 => '/dashboard/sims',
      2 => '/dashboard/alerts',
      _ => '/dashboard',
    };

    context.go(location);
  }
}
