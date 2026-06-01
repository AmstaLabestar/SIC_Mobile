import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/sic_amount_display.dart';
import '../../../../core/widgets/sic_error_widget.dart';
import '../../../../core/widgets/sic_loading.dart';
import '../../../balance_update/presentation/widgets/balance_update_bottom_sheet.dart';
import '../../domain/entities/agent_summary.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/benefit_chips.dart';
import '../widgets/benefit_summary_widget.dart';
import '../widgets/quick_actions_row.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: dashboardState.when(
          loading: () => const SicLoading(),
          error: (error, _) => SicErrorWidget(
            error: error,
            onRetry: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
          ),
          data: (summary) => RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () {
              return ref.read(dashboardNotifierProvider.notifier).refresh();
            },
            child: _DashboardContent(summary: summary),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.summary});

  final AgentSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _DashboardHeader(summary: summary)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary.hasLowBalance) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _LowBalanceBanner(),
                ],
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(
                  title: 'Mes soldes',
                  actionLabel: 'Gerer',
                  onActionTap: () => context.push('/dashboard/sims'),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 170,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: summary.balances.length,
                    separatorBuilder: (context, index) => const SizedBox(
                      width: AppSpacing.md,
                    ),
                    itemBuilder: (context, index) {
                      final balance = summary.balances[index];

                      return BalanceCard(
                        balance: balance,
                        onTap: () {
                          BalanceUpdateBottomSheet.show(context, balance);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionHeader(title: 'Benefices'),
                const SizedBox(height: AppSpacing.md),
                const BenefitChips(),
                const SizedBox(height: AppSpacing.md),
                BenefitSummaryWidget(summary: summary),
                const SizedBox(height: AppSpacing.xl),
                const _SectionHeader(title: 'Actions rapides'),
                const SizedBox(height: AppSpacing.md),
                QuickActionsRow(
                  onDepositTap: () => _showComingSoon(context),
                  onWithdrawalTap: () => _showComingSoon(context),
                  onTransferTap: () => _showComingSoon(context),
                  onTopUpTap: () => _showComingSoon(context),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalite prevue dans la suite.')),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.summary});

  final AgentSummary summary;

  @override
  Widget build(BuildContext context) {
    final firstName = summary.agentName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AgentAvatar(agentName: summary.agentName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bonjour, $firstName', style: AppTextStyles.titleLarge),
                    Text(summary.agentCode, style: AppTextStyles.caption),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              IconButton(
                tooltip: 'Parametres',
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                const Text('Solde total', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.sm),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: summary.totalBalance),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return SicAmountDisplay(
                      amount: value,
                      size: SicAmountSize.large,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${summary.activeSimCount} puces actives',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.05, end: 0),
        ],
      ),
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  const _AgentAvatar({required this.agentName});

  final String agentName;

  @override
  Widget build(BuildContext context) {
    final initials = agentName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary,
      child: Text(
        initials,
        style: AppTextStyles.titleMedium.copyWith(color: AppColors.surface),
      ),
    );
  }
}

class _LowBalanceBanner extends StatelessWidget {
  const _LowBalanceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Une puce a un solde faible. Pensez a compenser avant le prochain client.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
        if (actionLabel != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
