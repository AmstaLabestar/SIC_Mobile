import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const displayLarge = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: 'DM Sans',
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );

  static const titleLarge = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: 'DM Sans',
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const titleMedium = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: 'DM Sans',
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );

  static const bodyLarge = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: 'DM Sans',
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    color: AppColors.textSecondary,
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const caption = TextStyle(
    color: AppColors.textSecondary,
    fontFamily: 'DM Sans',
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const amount = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: 'Roboto Mono',
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static const amountSmall = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: 'Roboto Mono',
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );
}
