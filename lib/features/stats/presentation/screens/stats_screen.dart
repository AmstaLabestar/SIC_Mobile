import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/sic_error_widget.dart';
import '../../../../core/widgets/sic_loading.dart';
import '../../../../core/widgets/soon_badge.dart';
import '../../../dashboard/domain/entities/agent_summary.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

import 'package:go_router/go_router.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Statistiques d\'Activité',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            fontSize: 19,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: SafeArea(
        child: dashboardState.when(
          loading: () => const SicLoading(),
          error: (error, _) => SicErrorWidget(
            error: error,
            onRetry: () =>
                ref.read(dashboardNotifierProvider.notifier).refresh(),
          ),
          data: (summary) => _StatsContent(summary: summary),
        ),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.summary});

  final AgentSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        Text('Stats', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Suivez l\'activité et les statistiques globales.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        _StatInfoTile(
          icon: Icons.receipt_long_outlined,
          title: 'Historique transactions',
          value: '${summary.transactionCountToday} operations aujourd hui',
          caption: 'Detail complet dans l onglet Transactions.',
        ),
        const SizedBox(height: AppSpacing.md),
        const _StatInfoTile(
          icon: Icons.pie_chart_outline_rounded,
          title: 'Repartition par operateur',
          value: 'Analyse a venir',
          caption: 'Orange, Moov, Telecel et autres reseaux.',
          soon: true,
        ),
      ],
    );
  }
}

class _StatInfoTile extends StatelessWidget {
  const _StatInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    this.soon = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (soon) ...[
                      const SizedBox(width: 8),
                      const SoonBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
