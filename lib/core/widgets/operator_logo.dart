import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum OperatorLogoShape { circle, roundedSquare }

class OperatorLogo extends StatelessWidget {
  const OperatorLogo({
    super.key,
    required this.operatorCode,
    this.size = 40,
    this.shape = OperatorLogoShape.circle,
  });

  final String operatorCode;
  final double size;
  final OperatorLogoShape shape;

  @override
  Widget build(BuildContext context) {
    final config = _OperatorLogoConfig.fromCode(operatorCode);
    final borderRadius = shape == OperatorLogoShape.circle
        ? BorderRadius.circular(size / 2)
        : BorderRadius.circular(10);

    return Semantics(
      image: true,
      label: 'Operateur ${config.label}',
      child: Container(
        height: size,
        width: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: borderRadius,
        ),
        child: Text(
          config.shortLabel,
          style: TextStyle(
            color: config.foregroundColor,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OperatorLogoConfig {
  const _OperatorLogoConfig({
    required this.label,
    required this.shortLabel,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final String shortLabel;
  final Color backgroundColor;
  final Color foregroundColor;

  factory _OperatorLogoConfig.fromCode(String code) {
    final normalizedCode = code.toUpperCase();

    return switch (normalizedCode) {
      'OM' => const _OperatorLogoConfig(
          label: 'Orange Money',
          shortLabel: 'OM',
          backgroundColor: Color(0xFFFF6600),
          foregroundColor: AppColors.surface,
        ),
      'MOOV' => const _OperatorLogoConfig(
          label: 'Moov Money',
          shortLabel: 'MV',
          backgroundColor: Color(0xFF0066CC),
          foregroundColor: AppColors.surface,
        ),
      'TELECEL' => const _OperatorLogoConfig(
          label: 'Telecel Money',
          shortLabel: 'TC',
          backgroundColor: Color(0xFF009933),
          foregroundColor: AppColors.surface,
        ),
      'MTN' => const _OperatorLogoConfig(
          label: 'MTN Money',
          shortLabel: 'MTN',
          backgroundColor: Color(0xFFFFCC00),
          foregroundColor: AppColors.textPrimary,
        ),
      _ => _OperatorLogoConfig(
          label: normalizedCode,
          shortLabel: normalizedCode.substring(
            0,
            normalizedCode.length < 2 ? normalizedCode.length : 2,
          ),
          backgroundColor: AppColors.textSecondary,
          foregroundColor: AppColors.surface,
        ),
    };
  }
}
