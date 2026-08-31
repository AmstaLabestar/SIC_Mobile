import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/operator_logo.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/role_chip.dart';
import '../../../../core/widgets/sic_error_widget.dart';
import '../../../../core/widgets/sic_loading.dart';
import '../../../transactions/domain/entities/agent_transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/agent_summary.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/add_sim_sheet.dart';
import '../widgets/modify_sim_sheet.dart';
import '../widgets/operations_bar.dart';
import '../widgets/sim_cards_section.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardNotifierProvider);

    return SafeArea(
      bottom: false,
      child: dashboardState.when(
        loading: () => const SicLoading(),
        error: (error, _) => SicErrorWidget(
          error: error,
          onRetry: () => ref.read(dashboardNotifierProvider.notifier).refresh(),
        ),
        data: (summary) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(dashboardNotifierProvider.notifier).refresh(),
          child: _DashboardContent(summary: summary),
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
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: _Header(summary: summary),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

          // 2. Mes SIM — remonte a la place de l'ancien "solde total". Le vrai
          // solde operateur etant illisible, on n'affiche plus de solde total ;
          // les SIM servent a choisir source/destination des operations (le
          // montant sur la carte est masque/indicatif). Isole en RepaintBoundary.
          RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: SimCardsSection(
                balances: summary.balances,
                onManageTap: () => AddSimSheet.show(context),
                onHistoryTap: (balance) =>
                    _comingSoon(context, 'Historique ${balance.operatorName}'),
                onModifyTap: (balance) => ModifySimSheet.show(context, balance),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 400.ms)
              .slideY(begin: 0.1, end: 0),

          // 3. Operations (actions principales, sans scroll)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SectionTitle('Operations'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: OperationsBar(
              operations: [
                Operation(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Dépôt',
                  color: AppColors.primary,
                  onTap: () => context.push('/operations/depot'),
                ),
                Operation(
                  icon: Icons.near_me_rounded,
                  label: 'Envoyer',
                  color: AppColors.primary,
                  onTap: () => context.push('/operations/envoyer'),
                ),
                Operation(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Conversion',
                  color: AppColors.primary,
                  onTap: () => context.push('/operations/transfert'),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(
                begin: 0.1,
                end: 0,
              ),

          // 4. Activité récente
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _SectionTitle('Activité récente'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ref.watch(transactionsNotifierProvider).when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                  error: (err, _) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.danger.withOpacity(0.12)),
                    ),
                    child: Text(
                      'Impossible de charger l\'activité récente.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                  data: (txns) {
                    if (txns.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.02),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Aucune transaction',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Vos récentes opérations s\'afficheront ici',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final recent = txns.take(3).toList();
                    return Column(
                      children: [
                        for (final txn in recent) ...[
                          _DashboardTxnTile(txn: txn),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                begin: 0.1,
                end: 0,
              ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('$label — bientot disponible.'),
        ),
      );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.sectionTitle);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary});

  final AgentSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar -> acces parametres.
        Pressable(
          onTap: () => context.push('/dashboard/settings'),
          semanticLabel: 'Profil et parametres',
          child: Container(
            height: 52,
            width: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(summary.agentInitials,
                style: AppTextStyles.avatarInitials),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                summary.agentName,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              const RoleChip(isAgent: true, compact: true),
            ],
          ),
        ),

        _HeaderIconButton(
          icon: Icons.insights_rounded,
          tooltip: 'Statistiques',
          onTap: () => context.push('/dashboard/stats'),
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.notifications_outlined,
          tooltip: 'Notifications',
          hasBadge: summary.hasUnreadNotifications,
          onTap: () => context.push('/dashboard/alerts'),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.hasBadge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool hasBadge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      semanticLabel: tooltip,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            if (hasBadge)
              Positioned(
                top: 9,
                right: 9,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTxnTile extends StatelessWidget {
  const _DashboardTxnTile({required this.txn});

  final AgentTransaction txn;

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.kind == TransactionKind.deposit;
    final operatorLabel =
        (txn.operatorName != null && txn.operatorName!.isNotEmpty)
            ? txn.operatorName!
            : 'SIC';
    final title = isIncome ? 'Reçu de $operatorLabel' : 'Vers $operatorLabel';

    final dateStr =
        '${txn.createdAt.day.toString().padLeft(2, '0')}/${txn.createdAt.month.toString().padLeft(2, '0')} · ${txn.createdAt.hour.toString().padLeft(2, '0')}:${txn.createdAt.minute.toString().padLeft(2, '0')}';

    final statusColor = txn.isSuccess
        ? AppColors.primary
        : (txn.isFailed ? AppColors.danger : AppColors.warning);
    final statusText =
        txn.isSuccess ? 'Réussi' : (txn.isFailed ? 'Échoué' : 'En attente');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          OperatorLogo(
            operatorCode: txn.operatorCode ?? '',
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? "+ " : "- "}${txn.amount.round()} F',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
