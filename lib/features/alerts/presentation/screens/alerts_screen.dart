import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/fcfa_formatter.dart';
import '../../../../core/widgets/sic_error_widget.dart';
import '../../../../core/widgets/sic_loading.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/domain/entities/agent_transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../domain/entities/alert_config.dart';
import '../providers/alert_provider.dart';
import '../widgets/alert_config_tile.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertState = ref.watch(alertNotifierProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final txnsState = ref.watch(transactionsNotifierProvider);

    final kycStatus = (user?.kycStatus ?? 'PENDING').toUpperCase();
    final isKycApproved = kycStatus == 'APPROVED';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
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
        title: Text(
          'Alertes & Notifications',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            fontSize: 19,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              ref.read(alertNotifierProvider.notifier).refresh();
              ref.read(transactionsNotifierProvider.notifier).refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Toutes (SIC)'),
            Tab(text: 'Validations'),
            Tab(text: 'Seuils Puces'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Onglet 1 : Toutes les alertes & notifications
            _buildAllNotificationsView(
              context,
              ref,
              user,
              isKycApproved,
              txnsState,
              alertState,
            ),

            // Onglet 2 : Validations Backoffice (KYC + Opérations)
            _buildBackofficeValidationsView(
              context,
              isKycApproved,
              txnsState,
            ),

            // Onglet 3 : Configuration des seuils puces
            _buildAlertConfigsView(ref, alertState),
          ],
        ),
      ),
    );
  }

  Widget _buildAllNotificationsView(
    BuildContext context,
    WidgetRef ref,
    AuthUser? user,
    bool isKycApproved,
    AsyncValue<List<AgentTransaction>> txnsState,
    AsyncValue<List<AlertConfig>> alertState,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await ref.read(alertNotifierProvider.notifier).refresh();
        await ref.read(transactionsNotifierProvider.notifier).refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 1. Raccourci vers l'historique complet
          _buildHistoryShortcutTile(context),
          const SizedBox(height: AppSpacing.md),

          // 2. Notification de validation KYC Backoffice
          _buildKycValidationCard(isKycApproved),
          const SizedBox(height: AppSpacing.md),

          // 3. Titre Section Validations récentes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Validations d\'opérations',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/transactions'),
                child: Text(
                  'Voir l\'historique',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Liste des notifications de transactions validées
          txnsState.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: SicLoading(),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (txns) {
              if (txns.isEmpty) {
                return _buildEmptyStateCard(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Aucune notification d\'opération',
                  subtitle:
                      'Les validations de vos dépôts, retraits et transferts s\'afficheront ici.',
                );
              }

              final validTxns = txns.take(5).toList();
              return Column(
                children: [
                  for (final txn in validTxns) ...[
                    _buildTxnValidationCard(txn),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),

          // 5. Configuration des seuils d'alertes
          Text(
            'Seuils de sécurité Puces',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          alertState.when(
            loading: () => const SizedBox.shrink(),
            error: (err, _) => _buildEmptyStateCard(
              icon: Icons.shield_outlined,
              title: 'Seuils de sécurité par défaut',
              subtitle: 'Alerte active à partir de 50.000 FCFA de solde.',
            ),
            data: (configs) {
              if (configs.isEmpty) {
                return _buildEmptyStateCard(
                  icon: Icons.shield_outlined,
                  title: 'Seuils automatiques actifs',
                  subtitle:
                      'Le système vous alerte dès qu\'un solde de puce est faible.',
                );
              }
              return Column(
                children: [
                  for (final config in configs) ...[
                    AlertConfigTile(config: config),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackofficeValidationsView(
    BuildContext context,
    bool isKycApproved,
    AsyncValue<List<AgentTransaction>> txnsState,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _buildKycValidationCard(isKycApproved),
        const SizedBox(height: AppSpacing.md),

        Text(
          'Activités validées en Backoffice',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 10),

        txnsState.when(
          loading: () => const SicLoading(),
          error: (err, _) => SicErrorWidget(
            error: err,
            onRetry: () => ref.read(transactionsNotifierProvider.notifier).refresh(),
          ),
          data: (txns) {
            if (txns.isEmpty) {
              return _buildEmptyStateCard(
                icon: Icons.verified_outlined,
                title: 'Aucune validation enregistrée',
                subtitle: 'Vos futures transactions validées apparaîtront ici.',
              );
            }
            return Column(
              children: [
                for (final txn in txns) ...[
                  _buildTxnValidationCard(txn),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlertConfigsView(WidgetRef ref, AsyncValue<List<AlertConfig>> alertState) {
    return alertState.when(
      loading: () => const SicLoading(),
      error: (error, _) => SicErrorWidget(
        error: error,
        onRetry: () => ref.read(alertNotifierProvider.notifier).refresh(),
      ),
      data: (configs) {
        if (configs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildEmptyStateCard(
                icon: Icons.notifications_off_outlined,
                title: 'Aucun seuil d\'alerte défini',
                subtitle:
                    'Les seuils d\'alerte vous permettent de recevoir une notification avant qu\'un solde de puce n\'atteigne zéro.',
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: configs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            return AlertConfigTile(config: configs[index]);
          },
        );
      },
    );
  }

  Widget _buildHistoryShortcutTile(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/transactions'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF172554)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historique des transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Journal complet de tous vos dépôts, retraits & transferts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKycValidationCard(bool isKycApproved) {
    if (isKycApproved) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5), // Emerald light
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Compte & KYC Validés',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF065F46),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF047857),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Backoffice',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Votre identité est certifiée. Vos plafonds de transaction sont entièrement débloqués sur le réseau SIC.',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF047857),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Amber light
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vérification KYC en cours',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre dossier d\'identité est transmis à l\'équipe Backoffice pour validation finale.',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFFB45309),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxnValidationCard(AgentTransaction txn) {
    final isSuccess = txn.isSuccess;
    final isFailed = txn.isFailed;

    final color = isSuccess
        ? const Color(0xFF10B981)
        : (isFailed ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
    final bgColor = isSuccess
        ? const Color(0xFFECFDF5)
        : (isFailed ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB));

    final title = 'Validation Opération · ${txn.operatorName ?? "SIC"}';
    final amountFormatted = FcfaFormatter.format(txn.amount);
    final dateStr =
        '${txn.createdAt.day.toString().padLeft(2, '0')}/${txn.createdAt.month.toString().padLeft(2, '0')} à ${txn.createdAt.hour.toString().padLeft(2, '0')}:${txn.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : (isFailed ? Icons.cancel_rounded : Icons.pending_rounded),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      amountFormatted,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isSuccess ? 'Confirmé' : (isFailed ? 'Rejeté' : 'En cours'),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
