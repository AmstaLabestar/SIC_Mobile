import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/fcfa_formatter.dart';
import '../../../../core/widgets/operator_logo.dart';
import '../../../../core/widgets/sic_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/domain/entities/agent_transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

/// Accueil du compte CLIENT (lot D1-2) adapté au nouveau design premium.
///
/// Affiche le profil de l'agent, les actions rapides (Envoyer / Recevoir),
/// un bandeau de parrainage vert interactif, les fonctionnalités clés (Sécurité,
/// Convertir, Identité, Historique) et les dernières activités du client.
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final firstName = (user?.firstName.trim().isNotEmpty ?? false)
        ? user!.firstName
        : 'Client SIC';
    final phoneNumber = user?.phoneNumber ?? '';

    final txnsState = ref.watch(transactionsNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(transactionsNotifierProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. En-tête de bienvenue style Profil + Notifications
              _buildHeader(context, firstName),
              const SizedBox(height: AppSpacing.lg),

              // 2. Actions rapides (Envoyer / Recevoir)
              _buildQuickActions(context, phoneNumber),
              const SizedBox(height: AppSpacing.lg),

              // 4. Section Services (Sécurité, Convertir, Identité, Historique)
              _buildServicesSection(context),
              const SizedBox(height: AppSpacing.xl),

              // 5. Section Activités récentes
              _buildActivitiesSection(context, txnsState),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Helpers ---

  Widget _buildHeader(BuildContext context, String firstName) {
    return Row(
      children: [
        // Cercle Avatar avec initiale du prénom
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.08),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.12), width: 1.5),
          ),
          child: Center(
            child: Text(
              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Salutations
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bonjour,',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                firstName,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Cloche de notifications
        IconButton(
          onPressed: () => context.push('/dashboard/alerts'),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimary,
                size: 26,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary, // Orange dot
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, String phoneNumber) {
    return Row(
      children: [
        // Bouton Envoyer (Orange)
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/operations/envoyer'),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE0703C), // Orange vif
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE0703C).withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.north_east_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Envoyer',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Bouton Recevoir (Beige/Pêche)
        Expanded(
          child: GestureDetector(
            onTap: () => _showReceiveSheet(context, phoneNumber),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E1), // Beige/pêche clair
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.south_west_rounded,
                    color: Color(0xFF1E293B), // Slate 800
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Recevoir',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showReceiveSheet(BuildContext context, String phoneNumber) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Logo et QR Code
            const Center(
              child: SicLogo(size: 64),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 140,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Recevoir de l\'argent',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Présentez ce code ou communiquez votre numéro de téléphone SIC pour recevoir des fonds.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_android_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    phoneNumber,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ServiceButton(
              icon: Icons.swap_horiz_rounded,
              label: 'Convertir',
              onTap: () => context.push('/operations/transfert'),
            ),
            _ServiceButton(
              icon: Icons.badge_outlined,
              label: 'Identité',
              onTap: () => context.push('/kyc'),
            ),
            _ServiceButton(
              icon: Icons.receipt_long_rounded,
              label: 'Historique',
              onTap: () => context.go('/transactions'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivitiesSection(
    BuildContext context,
    AsyncValue<List<AgentTransaction>> state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/transactions'),
              child: Text(
                'Voir tout',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        state.when(
          loading: () => Container(
            height: 90,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Impossible de charger les activités récentes.',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
          data: (txns) {
            if (txns.isEmpty) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.textTertiary.withOpacity(0.6),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune activité récente',
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }

            final recent = txns.take(3).toList();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final txn = recent[index];
                return _ClientTxnCard(txn: txn);
              },
            );
          },
        ),
      ],
    );
  }
}

class _ServiceButton extends StatelessWidget {
  const _ServiceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ClientTxnCard extends StatelessWidget {
  const _ClientTxnCard({required this.txn});

  final AgentTransaction txn;

  @override
  Widget build(BuildContext context) {
    // Calcul des libellés visuels
    final isIncome = txn.kind == TransactionKind.deposit;
    final operatorLabel =
        (txn.operatorName != null && txn.operatorName!.isNotEmpty)
            ? txn.operatorName!
            : 'SIC';
    final title = isIncome ? 'Reçu de $operatorLabel' : 'Vers $operatorLabel';

    // Formater la date en 08/05 · 19:01
    final dateStr = _formatTxnDate(txn.createdAt);

    // Couleur du badge de statut
    final statusColor = txn.isSuccess
        ? AppColors.success
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
          // Logo opérateur ou icône générique
          OperatorLogo(
            operatorCode: txn.operatorCode ?? '',
            size: 40,
          ),
          const SizedBox(width: 12),
          // Colonne Titre + Date
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
          // Colonne Montant + Statut Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? "+ " : "- "}${FcfaFormatter.format(txn.amount)}',
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

  String _formatTxnDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$min';
  }
}
