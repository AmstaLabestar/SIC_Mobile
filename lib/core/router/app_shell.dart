import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: NavigationBar(
                height: 68,
                elevation: 0,
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.primary.withValues(alpha: 0.10),
                selectedIndex: _selectedIndex(context),
                onDestinationSelected: (index) => _goToTab(context, index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Operations',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_rounded),
                    selectedIcon: Icon(Icons.bar_chart_rounded),
                    label: 'Stats',
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
            ),
          ),
        ),
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    if (location.startsWith('/dashboard/stats')) {
      return 1;
    }

    if (location.startsWith('/dashboard/sims')) {
      return 2;
    }

    if (location.startsWith('/dashboard/alerts')) {
      return 3;
    }

    return 0;
  }

  void _goToTab(BuildContext context, int index) {
    final location = switch (index) {
      0 => '/dashboard',
      1 => '/dashboard/stats',
      2 => '/dashboard/sims',
      3 => '/dashboard/alerts',
      _ => '/dashboard',
    };

    context.go(location);
  }
}
