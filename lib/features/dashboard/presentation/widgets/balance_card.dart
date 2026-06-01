import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/fcfa_formatter.dart';
import '../../../../core/widgets/operator_logo.dart';
import '../../domain/entities/balance_summary.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    this.onTap,
  });

  final BalanceSummary balance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = _BalanceStatus.fromBalance(balance);

    return Semantics(
      button: onTap != null,
      label: '${balance.operatorName}, ${FcfaFormatter.format(balance.balance)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 220,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: status.backgroundColor,
            border: Border.all(color: status.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OperatorLogo(operatorCode: balance.operatorCode),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.operatorName,
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _maskPhone(balance.phoneNumber),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                FcfaFormatter.format(balance.balance),
                style: AppTextStyles.amountSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      status.label,
                      style: AppTextStyles.caption.copyWith(color: status.color),
                    ),
                  ),
                  Text(
                    DateFormatter.formatRelative(balance.lastUpdated),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 260.ms).slideX(begin: 0.05, end: 0);
  }

  static String _maskPhone(String phoneNumber) {
    if (phoneNumber.length < 6) {
      return phoneNumber;
    }

    return '${phoneNumber.substring(0, 2)}***${phoneNumber.substring(
      phoneNumber.length - 3,
    )}';
  }
}

class _BalanceStatus {
  const _BalanceStatus({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color borderColor;
  final Color backgroundColor;

  factory _BalanceStatus.fromBalance(BalanceSummary balance) {
    if (balance.isEmpty) {
      return _BalanceStatus(
        label: 'Vide',
        color: AppColors.danger,
        borderColor: AppColors.danger.withValues(alpha: 0.45),
        backgroundColor: AppColors.danger.withValues(alpha: 0.07),
      );
    }

    if (balance.isLow) {
      return _BalanceStatus(
        label: 'Faible',
        color: AppColors.warning,
        borderColor: AppColors.warning.withValues(alpha: 0.55),
        backgroundColor: AppColors.surface,
      );
    }

    return const _BalanceStatus(
      label: 'OK',
      color: AppColors.success,
      borderColor: AppColors.cardBorder,
      backgroundColor: AppColors.surface,
    );
  }
}
