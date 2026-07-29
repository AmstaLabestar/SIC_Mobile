import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/fcfa_formatter.dart';
import '../../../../core/widgets/operator_logo.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/sic_error_widget.dart';
import '../../../../core/widgets/sic_loading.dart';
import '../../domain/entities/agent_transaction.dart';
import '../providers/transaction_providers.dart';

/// Écran d'Historique des Transactions (onglet Activité).
///
/// Permet de filtrer l'historique par statut (Réussis, En attente, Échoués,
/// Remboursés) et par réseau / opérateur (Moov, Orange, etc.).
/// Les transactions sont regroupées par date (ex: 08/05/2026).
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String?
      _statusFilter; // null = Tout, 'SUCCESS', 'PENDING', 'FAILED', 'REFUNDED'
  String?
      _operatorFilter; // null = Tous réseaux, 'OM', 'MOOV', 'TELECEL', 'MTN', 'WAVE'

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsNotifierProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(transactionsNotifierProvider.notifier).refresh(),
        child: state.when(
          loading: () => const _LoadingList(),
          error: (error, _) => ListView(
            children: [
              _Header(onFilterTap: _resetFilters),
              const SizedBox(height: 80),
              SicErrorWidget(
                error: error,
                onRetry: () =>
                    ref.read(transactionsNotifierProvider.notifier).refresh(),
              ),
            ],
          ),
          data: (all) {
            // 1. Filtrage par statut
            var filtered = all;
            if (_statusFilter != null) {
              filtered = filtered.where((t) {
                final status = t.status.toUpperCase();
                if (_statusFilter == 'SUCCESS') {
                  return status == 'SUCCESS';
                }
                if (_statusFilter == 'PENDING') {
                  return status == 'PENDING';
                }
                if (_statusFilter == 'FAILED') {
                  return status == 'FAILED' || status == 'EXPIRED';
                }
                if (_statusFilter == 'REFUNDED') {
                  return status == 'REFUNDED';
                }
                return true;
              }).toList();
            }

            // 2. Filtrage par opérateur / réseau
            if (_operatorFilter != null) {
              filtered = filtered
                  .where(
                      (t) => t.operatorCode?.toUpperCase() == _operatorFilter)
                  .toList();
            }

            // 3. Regroupement par date
            final Map<DateTime, List<AgentTransaction>> grouped = {};
            for (final t in filtered) {
              final date = DateTime(
                  t.createdAt.year, t.createdAt.month, t.createdAt.day);
              grouped.putIfAbsent(date, () => []).add(t);
            }
            final sortedDates = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // En-tête avec bouton de filtre
                SliverToBoxAdapter(
                  child: _Header(onFilterTap: _resetFilters),
                ),
                // Ligne 1 des filtres : Statuts
                SliverToBoxAdapter(
                  child: _StatusFilters(
                    selected: _statusFilter,
                    onChanged: (status) =>
                        setState(() => _statusFilter = status),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                // Ligne 2 des filtres : Opérateurs / Réseaux
                SliverToBoxAdapter(
                  child: _NetworkFilters(
                    selected: _operatorFilter,
                    onChanged: (op) => setState(() => _operatorFilter = op),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(),
                  )
                else
                  for (final date in sortedDates) ...[
                    // En-tête de date du groupe
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                        child: Text(
                          _formatGroupDate(date),
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    // Liste des transactions du jour
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.separated(
                        itemCount: grouped[date]!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final txn = grouped[date]![index];
                          return _TxnTile(txn: txn);
                        },
                      ),
                    ),
                  ],
                // Marge de sécurité de fin de défilement
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = null;
      _operatorFilter = null;
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Filtres réinitialisés.'),
          duration: Duration(seconds: 1),
        ),
      );
  }

  String _formatGroupDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onFilterTap});

  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Historique',
            style: AppTextStyles.titleLarge.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          // Bouton entonnoir de filtre en vert foncé (réinitialise)
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: const Icon(
                Icons.filter_alt_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Header(onFilterTap: () {}),
        const SizedBox(height: 120),
        const SicLoading(),
      ],
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <(String?, String)>[
      (null, 'Tous'),
      ('SUCCESS', 'Réussis'),
      ('PENDING', 'En attente'),
      ('FAILED', 'Échoués'),
      ('REFUNDED', 'Remboursés'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (type, label) = chips[index];
          final active = type == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(type);
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                  width: 1.2,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NetworkFilters extends StatelessWidget {
  const _NetworkFilters({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <(String?, String)>[
      (null, 'Tous réseaux'),
      ('MOOV', 'Moov Money'),
      ('OM', 'Orange Money'),
      ('MTN', 'MTN Money'),
      ('WAVE', 'Wave'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (code, label) = chips[index];
          final active = code == selected;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(code);
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (code != null) ...[
                    OperatorLogo(
                      operatorCode: code,
                      size: 16,
                      shape: OperatorLogoShape.roundedSquare,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.txn});

  final AgentTransaction txn;

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.kind == TransactionKind.deposit;
    final operatorLabel =
        (txn.operatorName != null && txn.operatorName!.isNotEmpty)
            ? txn.operatorName!
            : 'SIC';

    // Déterminer le titre (ex. Envoyé au 52962231 ou Reçu de Orange Money)
    final String title;
    if (isIncome) {
      title = 'Reçu de $operatorLabel';
    } else {
      if (txn.phoneNumber != null && txn.phoneNumber!.isNotEmpty) {
        title = 'Envoyé au ${txn.phoneNumber}';
      } else {
        title = 'Vers $operatorLabel';
      }
    }

    // Formater la date en 08/05/2026 à 19:01
    final dateStr = _formatTxnDateTime(txn.createdAt);

    // Badge de statut (icône + texte de couleur verte/rouge/orange, pas de fond opaque)
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    if (txn.isSuccess) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline_rounded;
      statusText = 'Réussi';
    } else if (txn.isFailed) {
      statusColor = AppColors.danger;
      statusIcon = Icons.highlight_off_rounded;
      statusText = 'Échoué';
    } else {
      statusColor = AppColors.warning;
      statusIcon = Icons.hourglass_empty_rounded;
      statusText = 'En attente';
    }

    return Pressable(
      onTap: () => _showDetails(context),
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Row(
          children: [
            // Logo opérateur
            OperatorLogo(
              operatorCode: txn.operatorCode ?? '',
              size: 42,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                // Icône + Texte du statut
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TxnDetailsSheet(txn: txn),
    );
  }

  String _formatTxnDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$min';
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: const BoxDecoration(
              color: AppColors.primaryBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primaryLight,
              size: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Aucune transaction', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text('Aucun enregistrement ne correspond aux filtres sélectionnés.',
              style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _TxnDetailsSheet extends StatelessWidget {
  const _TxnDetailsSheet({required this.txn});

  final AgentTransaction txn;

  @override
  Widget build(BuildContext context) {
    final visual = _TxnVisual.of(txn.kind);
    final statusColor = txn.isSuccess
        ? AppColors.success
        : (txn.isFailed ? AppColors.danger : AppColors.warning);
    final statusBg = statusColor.withOpacity(0.08);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: visual.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(visual.icon, color: visual.color, size: 32),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              '${visual.sign}${FcfaFormatter.format(txn.amount)}',
              style: AppTextStyles.titleLarge.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              visual.label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Text(
                _statusText(txn.status),
                style: AppTextStyles.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _DetailRow(label: 'Référence', value: txn.id, isCopyable: true),
          _DetailRow(
            label: 'Date & Heure',
            value:
                '${txn.createdAt.day.toString().padLeft(2, '0')}/${txn.createdAt.month.toString().padLeft(2, '0')}/${txn.createdAt.year} à ${txn.createdAt.hour.toString().padLeft(2, '0')}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
          ),
          if (txn.operatorName != null && txn.operatorName!.isNotEmpty)
            _DetailRow(label: 'Opérateur Cible', value: txn.operatorName!),
          if (txn.phoneNumber != null && txn.phoneNumber!.isNotEmpty)
            _DetailRow(label: 'Destinataire', value: txn.phoneNumber!),
          _DetailRow(
            label: 'Commission SIC',
            value: FcfaFormatter.format(txn.commissionSic),
          ),
          _DetailRow(
            label: 'Status de Compensation',
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: txn.isCompensated
                    ? AppColors.success.withOpacity(0.08)
                    : AppColors.textSecondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                txn.isCompensated ? 'Compensée' : 'Non compensée',
                style: AppTextStyles.caption.copyWith(
                  color: txn.isCompensated
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          if (txn.compensationDetails.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'PLAN DE COMPENSATION (Puces déduites)',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: txn.compensationDetails.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.border,
                  height: 1,
                  thickness: 1,
                ),
                itemBuilder: (context, idx) {
                  final detail = txn.compensationDetails[idx];
                  final detailColor = detail.isSuccess
                      ? AppColors.success
                      : (detail.isFailed
                          ? AppColors.danger
                          : AppColors.warning);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.puceOperator,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                detail.pucePhone,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '- ${FcfaFormatter.format(detail.amountDeducted)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _statusText(detail.status),
                              style: AppTextStyles.caption.copyWith(
                                color: detailColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  String _statusText(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
        return 'Réussi';
      case 'PENDING':
        return 'En attente';
      case 'FAILED':
        return 'Échoué';
      case 'EXPIRED':
        return 'Expiré';
      default:
        return status;
    }
  }
}

class _TxnVisual {
  const _TxnVisual({
    required this.label,
    required this.icon,
    required this.color,
    required this.sign,
    required this.amountColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String sign;
  final Color amountColor;

  factory _TxnVisual.of(TransactionKind kind) {
    return switch (kind) {
      TransactionKind.deposit => const _TxnVisual(
          label: 'Dépôt',
          icon: Icons.arrow_downward_rounded,
          color: AppColors.primary,
          sign: '+ ',
          amountColor: AppColors.primary,
        ),
      TransactionKind.withdrawal => const _TxnVisual(
          label: 'Retrait',
          icon: Icons.arrow_upward_rounded,
          color: AppColors.primary,
          sign: '- ',
          amountColor: AppColors.primary,
        ),
      TransactionKind.transfer => const _TxnVisual(
          label: 'Transfert',
          icon: Icons.swap_horiz_rounded,
          color: AppColors.primary,
          sign: '',
          amountColor: AppColors.primary,
        ),
      TransactionKind.other => const _TxnVisual(
          label: 'Opération',
          icon: Icons.receipt_long_rounded,
          color: AppColors.primary,
          sign: '',
          amountColor: AppColors.primary,
        ),
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.isCopyable = false,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isCopyable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (valueWidget != null)
            valueWidget!
          else if (value != null) ...[
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isCopyable) ...[
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copié dans le presse-papiers'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
