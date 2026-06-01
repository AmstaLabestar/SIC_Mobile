import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    this.onDepositTap,
    this.onWithdrawalTap,
    this.onTransferTap,
    this.onTopUpTap,
  });

  final VoidCallback? onDepositTap;
  final VoidCallback? onWithdrawalTap;
  final VoidCallback? onTransferTap;
  final VoidCallback? onTopUpTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionButton(
          icon: Icons.south_west_rounded,
          label: 'Depot',
          color: AppColors.success,
          onTap: onDepositTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickActionButton(
          icon: Icons.north_east_rounded,
          label: 'Retrait',
          color: AppColors.warning,
          onTap: onWithdrawalTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Transfert',
          color: AppColors.primary,
          onTap: onTransferTap,
        ),
        const SizedBox(width: AppSpacing.sm),
        _QuickActionButton(
          icon: Icons.phone_android_rounded,
          label: 'Recharge',
          color: AppColors.accent,
          onTap: onTopUpTap,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap?.call();
          },
          child: Container(
            height: 82,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color.withValues(alpha: 0.18)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: AppSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 240.ms).scale(
            begin: const Offset(0.96, 0.96),
            end: const Offset(1, 1),
          ),
    );
  }
}
