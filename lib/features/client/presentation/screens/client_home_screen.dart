import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/fcfa_formatter.dart';
import '../../../../core/widgets/operator_logo.dart';
import '../../../../core/widgets/role_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/domain/entities/agent_transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../account/presentation/providers/avatar_provider.dart';

/// Accueil du compte CLIENT (lot D1-2) adapté au nouveau design premium.
///
/// Affiche le profil de l'agent, les actions rapides (Envoyer / Retrait),
/// un bandeau de parrainage vert interactif, les fonctionnalités clés (Sécurité,
/// Convertir, Identité, Historique) et les dernières activités du client.
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';
    final phoneNumber = user?.phoneNumber ?? '';

    final txnsState = ref.watch(transactionsNotifierProvider);
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final balanceVisible = ref.watch(heroBalanceVisibleProvider);
    final avatarPath = ref.watch(avatarProvider);

    final totalBalance = dashboardState.when(
      data: (summary) => summary.totalBalance,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(transactionsNotifierProvider.notifier).refresh();
            await ref.read(dashboardNotifierProvider.notifier).refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. En-tête de bienvenue style Profil + Notifications
              _buildHeader(context, firstName, lastName, avatarPath),
              const SizedBox(height: AppSpacing.lg),

              // 2. Carte virtuelle Portefeuille (Solde total avec bouton oeil)
              _buildHeroCard(
                context,
                totalBalance,
                balanceVisible,
                () => ref.read(heroBalanceVisibleProvider.notifier).state = !balanceVisible,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Bandeau de vérification d'identité (si KYC non validé)
              _buildKycBanner(context, user?.kycStatus ?? 'PENDING'),

              // 4. Barre des actions rapides horizontales (Envoyer, Cashpower, Facture ONEA, Retrait)
              _buildQuickActionsBar(context, phoneNumber),
              const SizedBox(height: AppSpacing.xl),

              // 5. Section Transferts récents
              _buildActivitiesSection(context, txnsState),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets Helpers ---

  Widget _buildHeader(BuildContext context, String firstName, String lastName, String? avatarPath) {
    final displayName = firstName.trim().isNotEmpty
        ? '$firstName ${lastName.trim().isNotEmpty ? '${lastName.trim()[0]}.' : ''}'
        : 'Client SIC';

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.push('/profil'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.08),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: avatarPath != null && avatarPath.isNotEmpty && File(avatarPath).existsSync()
                  ? Image.file(
                      File(avatarPath),
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                    )
                  : Center(
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const RoleChip(isAgent: false, compact: true),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Cloche de notifications (Alertes)
        GestureDetector(
          onTap: () => context.push('/dashboard/alerts'),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1E293B),
                  size: 28,
                ),
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444), // Vibrant red dot
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    double totalBalance,
    bool balanceVisible,
    VoidCallback onToggleVisibility,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A), // Blue-900
            Color(0xFF172554), // Blue-955
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solde total',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              IconButton(
                onPressed: onToggleVisibility,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  balanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: balanceVisible
                      ? (FcfaFormatter.format(totalBalance).endsWith(' FCFA')
                          ? FcfaFormatter.format(totalBalance).substring(0, FcfaFormatter.format(totalBalance).length - 5)
                          : FcfaFormatter.format(totalBalance))
                      : '••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                TextSpan(
                  text: ' FCFA',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycBanner(BuildContext context, String kycStatus) {
    if (kycStatus.toUpperCase() == 'APPROVED') {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: InkWell(
        onTap: () => context.push('/kyc'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF), // Soft blue background
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFDBEAFE), // Soft blue circle
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF1D4ED8), // Vibrant blue shield icon
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vérifiez votre identité',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Débloquez les plafonds et sécurisez votre compte',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsBar(BuildContext context, String phoneNumber) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.arrow_outward_rounded,
            label: 'Envoyer',
            color: const Color(0xFF1E3A8A), // Dark blue
            bgColor: const Color(0xFFEFF6FF), // Soft blue background
            onTap: () => context.push('/operations/envoyer'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.electric_bolt_rounded,
            label: 'Cashpower',
            color: const Color(0xFF2563EB), // Royal Blue
            bgColor: const Color(0xFFEFF6FF), // Soft blue background
            onTap: () => context.push('/bills?service=CASHPOWER'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.water_drop_rounded,
            label: 'Facture ONEA',
            color: const Color(0xFF0284C7), // Sky blue
            bgColor: const Color(0xFFF0F9FF), // Soft sky blue background
            onTap: () => context.push('/bills?service=ONEA'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Retrait',
            color: const Color(0xFF1D4ED8), // Dark blue
            bgColor: const Color(0xFFEFF6FF), // Soft blue background
            onTap: () => context.push('/operations/retrait'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceiveSheet(BuildContext context, String phoneNumber) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, child) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Header Title
                const Text(
                  'Recevoir des fonds',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Présentez ce code unique ou partagez votre numéro pour être crédité instantanément.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // QR Code Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 130,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Scanner actif SIC',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Phone / Account number Box with Copy Action
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.phone_android_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Numéro de compte SIC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              phoneNumber,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: phoneNumber));
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text('Numéro copié !'),
                                ),
                              );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(
                              Icons.copy_all_rounded,
                              color: Color(0xFF475569),
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Share coordinates Button
                FilledButton.icon(
                  onPressed: () {
                    final name = ref.read(authControllerProvider).valueOrNull?.fullName ?? '';
                    Clipboard.setData(ClipboardData(
                      text: 'Voici mes coordonnées SIC pour recevoir un transfert :\nNom : $name\nTéléphone : $phoneNumber',
                    ));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('Coordonnées copiées pour partage !'),
                        ),
                      );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Partager mes coordonnées',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
            const Text(
              'Transferts récents',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                fontSize: 18,
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
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFF1E293B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun transfert récent',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Envoyez de l'argent en quelques secondes",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/operations/envoyer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6), // Vibrant light blue button
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Envoyer de l'argent",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
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
