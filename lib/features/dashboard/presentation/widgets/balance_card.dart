import 'dart:ui';

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

class BalanceCard extends StatefulWidget {
  const BalanceCard({
    super.key,
    required this.balance,
    this.onTap,
  });

  final BalanceSummary balance;
  final VoidCallback? onTap;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isBalanceVisible = false;

  @override
  Widget build(BuildContext context) {
    final balance = widget.balance;
    final status = _BalanceStatus.fromBalance(balance);

    return Semantics(
      button: widget.onTap != null,
      label:
          '${balance.operatorName}, solde ${_isBalanceVisible ? FcfaFormatter.format(balance.balance) : 'masque'}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 220,
          padding: const EdgeInsets.all(AppSpacing.sm),
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
                  IconButton.filledTonal(
                    tooltip: 'Actualiser',
                    constraints: const BoxConstraints(
                      minHeight: 36,
                      minWidth: 36,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onTap?.call();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: _isBalanceVisible ? 0 : 5,
                          sigmaY: _isBalanceVisible ? 0 : 5,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _isBalanceVisible ? 1 : 0.48,
                          child: Text(
                            FcfaFormatter.format(balance.balance),
                            style: AppTextStyles.amountSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: _isBalanceVisible ? 'Masquer' : 'Afficher',
                    constraints: const BoxConstraints(
                      minHeight: 36,
                      minWidth: 36,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                    icon: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                  ),
                ],
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
                      style:
                          AppTextStyles.caption.copyWith(color: status.color),
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
