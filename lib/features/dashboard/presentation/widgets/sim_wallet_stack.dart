import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/soon_badge.dart';
import '../../domain/entities/balance_summary.dart';

/// Identite stable d'une SIM (cle de widget + etat de visibilite).
/// Deux puces du meme operateur restent distinctes grace a l'id backend
/// (fallback : operateur + numero).
String simIdentity(BalanceSummary b) =>
    b.id ?? '${b.operatorCode}_${b.phoneNumber}';

/// Pile de cartes SIM facon Apple Wallet : une carte depliee en haut, les
/// autres repliees en dessous. Un tap sur une carte repliee la fait remonter.
class SimWalletStack extends ConsumerStatefulWidget {
  const SimWalletStack({
    super.key,
    required this.balances,
    this.onCardTap,
    this.onHistory,
    this.onModify,
  });

  final List<BalanceSummary> balances;
  final ValueChanged<BalanceSummary>? onCardTap;
  final ValueChanged<BalanceSummary>? onHistory;
  final ValueChanged<BalanceSummary>? onModify;

  @override
  ConsumerState<SimWalletStack> createState() => _SimWalletStackState();
}

class _SimWalletStackState extends ConsumerState<SimWalletStack> {
  static const double _expandedH = 154;
  static const double _peek = 48;
  static const double _overlap = 14;

  int _selected = 0;

  void _select(int index) {
    if (_selected == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final balances = widget.balances;
    if (balances.isEmpty) return const SizedBox.shrink();
    if (_selected >= balances.length) _selected = 0;

    if (balances.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(height: _expandedH, child: _expandedCard(balances.first)),
      );
    }

    final collapsed = <int>[
      for (var i = 0; i < balances.length; i++)
        if (i != _selected) i,
    ];

    final totalHeight = _expandedH + collapsed.length * _peek;

    final children = <Widget>[];
    for (var j = 0; j < collapsed.length; j++) {
      final index = collapsed[j];
      children.add(
        AnimatedPositioned(
          key: ValueKey('sim_${simIdentity(balances[index])}'),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: 20,
          right: 20,
          top: _expandedH - _overlap + j * _peek,
          height: _peek + _overlap,
          child: _CollapsedCard(
            balance: balances[index],
            onTap: () => _select(index),
          ),
        ),
      );
    }
    children.add(
      AnimatedPositioned(
        key: ValueKey('sim_${simIdentity(balances[_selected])}'),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        left: 20,
        right: 20,
        top: 0,
        height: _expandedH,
        child: _expandedCard(balances[_selected]),
      ),
    );

    return SizedBox(
      height: totalHeight,
      child: Stack(children: children),
    );
  }

  Widget _expandedCard(BalanceSummary balance) {
    final gradient = _operatorGradient(balance.operatorCode);
    final status = _statusOf(balance);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onCardTap?.call(balance);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: gradient,
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.24),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: OverflowBox(
            minHeight: _expandedH,
            maxHeight: _expandedH,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          balance.operatorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusChip(status: status),
                    ],
                  ),
                  const Spacer(),
                  // Solde MASQUE : le vrai solde operateur n'est pas lisible, on
                  // n'affiche donc aucun montant (indicatif seulement).
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_off_rounded,
                        size: 16,
                        color: AppColors.onPrimary.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Solde masque',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onPrimary.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _GlassButton(
                          icon: Icons.history_rounded,
                          label: 'Historique',
                          soon: true,
                          onTap: () => widget.onHistory?.call(balance),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _GlassButton(
                          icon: Icons.edit_outlined,
                          label: 'Modifier',
                          solid: true,
                          onTap: () => widget.onModify?.call(balance),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _CollapsedCard extends StatelessWidget {
  const _CollapsedCard({required this.balance, required this.onTap});

  final BalanceSummary balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = _operatorGradient(balance.operatorCode);
    final status = _statusOf(balance);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: gradient,
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: status.dotOnGradient,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${balance.operatorName} · ${balance.maskedPhone}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            // Solde masque (indicatif) — pas de montant reel.
            Icon(
              Icons.visibility_off_rounded,
              size: 14,
              color: AppColors.onPrimary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.label,
    this.solid = false,
    this.soon = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool solid;
  final bool soon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.onPrimary.withOpacity(solid ? 0.24 : 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.onPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );

    if (!soon) return button;
    // Badge "Bientot" en coin (deborde legerement le bouton, reste dans la carte).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        const Positioned(top: -9, right: -4, child: SoonBadge(dense: true)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _SimStatusData status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SimStatusData {
  const _SimStatusData({required this.label, required this.dotOnGradient});

  final String label;
  final Color dotOnGradient;
}

_SimStatusData _statusOf(BalanceSummary balance) {
  if (balance.isEmpty) {
    return const _SimStatusData(label: 'Vide', dotOnGradient: Color(0xFFFFD2D2));
  }
  if (balance.isLow) {
    return const _SimStatusData(label: 'Faible', dotOnGradient: Color(0xFFFFE3B0));
  }
  return const _SimStatusData(label: 'OK', dotOnGradient: Color(0xFFFFFFFF));
}

LinearGradient _operatorGradient(String code) {
  final colors = switch (code.toUpperCase()) {
    'OM' => AppColors.orangeGradient,
    'MOOV' => AppColors.moovGradient,
    'TELECEL' => AppColors.telecelGradient,
    'MTN' => AppColors.mtnGradient,
    'WAVE' => const [Color(0xFF1A73E8), Color(0xFF4BA3F5)],
    'CORIS' => const [Color(0xFF8B1A1A), Color(0xFFBF4040)],
    _ => const [Color(0xFF334155), Color(0xFF64748B)],
  };
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors,
  );
}
