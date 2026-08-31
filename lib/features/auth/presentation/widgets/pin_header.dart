import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';

/// En-tete degrade (style hero du dashboard) partage par les ecrans PIN
/// (creation et verrouillage). [child] accueille en general des [PinDots].
class PinGradientHeader extends StatelessWidget {
  const PinGradientHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.child,
    this.showBack = false,
    this.onBack,
    this.subtitleError = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? child;
  final bool showBack;
  final VoidCallback? onBack;
  final bool subtitleError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 36,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: showBack
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.onPrimary,
                            size: 20,
                          ),
                          onPressed: onBack,
                        )
                      : null,
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.onPrimary.withOpacity(0.18),
                  border: Border.all(
                    color: AppColors.onPrimary.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: AppColors.onPrimary, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: subtitleError
                      ? const Color(0xFFFFD2D2)
                      : AppColors.onPrimary.withOpacity(0.9),
                  fontSize: 13.5,
                  height: 1.35,
                ),
                textAlign: TextAlign.center,
              ),
              if (child != null) ...[
                const SizedBox(height: 18),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Banniere d'erreur (fond rouge clair) partagee par les ecrans PIN.
class PinErrorBanner extends StatelessWidget {
  const PinErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
