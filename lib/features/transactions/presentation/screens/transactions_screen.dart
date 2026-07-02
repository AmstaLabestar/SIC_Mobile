import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_gradients.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/fcfa_formatter.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/sic_error_widget.dart';
import '../../../../core/widgets/sic_loading.dart';
import '../../domain/entities/agent_transaction.dart';
import '../providers/transaction_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  TransactionKind? _filter; // null = tout

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
              const _Header(),
              const SizedBox(height: 80),
              SicErrorWidget(
                error: error,
                onRetry: () =>
                    ref.read(transactionsNotifierProvider.notifier).refresh(),
              ),
            ],
          ),
          data: (all) {
            final txns = _filter == null
                ? all
                : all.where((t) => t.kind == _filter).toList();
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                SliverToBoxAdapter(
                  child: _Filters(
                    selected: _filter,
                    onChanged: (f) => setState(() => _filter = f),
                  ),
                ),
                if (txns.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: txns.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          _TxnTile(txn: txns[index]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transactions', style: AppTextStyles.titleLarge),
          const SizedBox(height: 2),
          Text('Historique de vos opérations.', style: AppTextStyles.caption),
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
      children: const [
        _Header(),
        SizedBox(height: 120),
        SicLoading(),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected, required this.onChanged});

  final TransactionKind? selected;
  final ValueChanged<TransactionKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <(TransactionKind?, String)>[
      (null, 'Tout'),
      (TransactionKind.deposit, 'Dépôts'),
      (TransactionKind.withdrawal, 'Retraits'),
      (TransactionKind.transfer, 'Transferts'),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (type, label) = chips[index];
          final active = type == selected;
          return Pressable(
            onTap: () => onChanged(type),
            pressedScale: 0.95,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: active ? AppColors.onPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
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
    final visual = _TxnVisual.of(txn.kind);
    final subtitle = [
      (txn.operatorName != null && txn.operatorName!.isNotEmpty)
          ? txn.operatorName!
          : 'Entre puces',
      _statusLabel(txn),
      _relativeTime(txn.createdAt),
    ].join(' · ');

    return Pressable(
      onTap: () => _showDetails(context),
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.02),
              blurRadius: 10,
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
                gradient: AppGradients.soft(visual.color),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(visual.icon, color: visual.color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    visual.label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${visual.sign}${FcfaFormatter.format(txn.amount)}',
              style: AppTextStyles.caption.copyWith(
                color: visual.amountColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
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

  String _statusLabel(AgentTransaction t) {
    if (t.isPending) return 'En attente';
    if (t.isFailed) return 'Échoué';
    if (t.isSuccess) return 'Réussi';
    return t.status;
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
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
          color: AppColors.secondary,
          sign: '+ ',
          amountColor: AppColors.secondary,
        ),
      TransactionKind.withdrawal => const _TxnVisual(
          label: 'Retrait',
          icon: Icons.arrow_upward_rounded,
          color: AppColors.primaryLight,
          sign: '- ',
          amountColor: AppColors.danger,
        ),
      TransactionKind.transfer => const _TxnVisual(
          label: 'Transfert',
          icon: Icons.swap_horiz_rounded,
          color: Color(0xFF534AB7),
          sign: '',
          amountColor: AppColors.textPrimary,
        ),
      TransactionKind.other => const _TxnVisual(
          label: 'Opération',
          icon: Icons.receipt_long_rounded,
          color: AppColors.primaryLight,
          sign: '',
          amountColor: AppColors.textPrimary,
        ),
    };
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
          Text('Vos opérations apparaîtront ici.',
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
        color: AppColors.background,
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
                gradient: AppGradients.soft(visual.color),
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
            value: '${txn.createdAt.day.toString().padLeft(2, '0')}/${txn.createdAt.month.toString().padLeft(2, '0')}/${txn.createdAt.year} à ${txn.createdAt.hour.toString().padLeft(2, '0')}:${txn.createdAt.minute.toString().padLeft(2, '0')}',
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
                  color: txn.isCompensated ? AppColors.success : AppColors.textSecondary,
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
                separatorBuilder: (_, __) => Divider(
                  color: AppColors.border,
                  height: 1,
                  thickness: 1,
                ),
                itemBuilder: (context, idx) {
                  final detail = txn.compensationDetails[idx];
                  final detailColor = detail.isSuccess
                      ? AppColors.success
                      : (detail.isFailed ? AppColors.danger : AppColors.warning);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
