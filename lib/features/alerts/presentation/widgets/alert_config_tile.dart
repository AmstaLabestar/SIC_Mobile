import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/fcfa_formatter.dart';
import '../../../../core/widgets/operator_logo.dart';
import '../../domain/entities/alert_config.dart';
import '../providers/alert_provider.dart';
import 'threshold_slider.dart';

class AlertConfigTile extends ConsumerStatefulWidget {
  const AlertConfigTile({super.key, required this.config});

  final AlertConfig config;

  @override
  ConsumerState<AlertConfigTile> createState() => _AlertConfigTileState();
}

class _AlertConfigTileState extends ConsumerState<AlertConfigTile> {
  late AlertConfig _draftConfig;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _draftConfig = widget.config;
  }

  @override
  void didUpdateWidget(covariant AlertConfigTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _draftConfig = widget.config;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OperatorLogo(operatorCode: _draftConfig.operatorCode),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_draftConfig.operatorName} · ${_draftConfig.phoneNumber}',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _draftConfig.isEnabled ? 'Alerte active' : 'Alerte inactive',
                      style: AppTextStyles.caption.copyWith(
                        color: _draftConfig.isEnabled ? AppColors.success : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _draftConfig.isEnabled,
                activeColor: AppColors.success,
                onChanged: (value) {
                  _updateDraft(_draftConfig.copyWith(isEnabled: value));
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ThresholdSlider(
            value: _draftConfig.threshold,
            isEnabled: _draftConfig.isEnabled,
            onChanged: (value) {
              _updateDraft(_draftConfig.copyWith(threshold: value));
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _draftConfig.isEnabled
                  ? AppColors.primary.withOpacity(0.04)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _draftConfig.isEnabled
                    ? AppColors.primary.withOpacity(0.08)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _draftConfig.isEnabled
                      ? Icons.info_outline_rounded
                      : Icons.notifications_off_outlined,
                  color: _draftConfig.isEnabled ? AppColors.primary : const Color(0xFF64748B),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _draftConfig.isEnabled
                        ? 'Alerte si solde ${_draftConfig.phoneNumber} < ${FcfaFormatter.format(_draftConfig.threshold)}'
                        : 'Aucune alerte configurée pour ${_draftConfig.phoneNumber}',
                    style: TextStyle(
                      color: _draftConfig.isEnabled ? AppColors.textPrimary : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateDraft(AlertConfig config) {
    setState(() => _draftConfig = config);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      ref.read(alertNotifierProvider.notifier).save(_draftConfig);
    });
  }
}
